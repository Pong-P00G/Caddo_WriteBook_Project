import 'dart:convert';

class NoteModel {
  final String id;
  final String userId;
  final String? workspaceId;
  final String? folderId;
  final String title;
  final String content;
  final String? slug;
  final List<String> tagIds;
  final bool isFavorite;
  final bool isDeleted;
  final DateTime updatedAt;
  final DateTime createdAt;

  NoteModel({
    required this.id,
    required this.userId,
    this.workspaceId,
    this.folderId,
    required this.title,
    required this.content,
    this.slug,
    this.tagIds = const [],
    this.isFavorite = false,
    this.isDeleted = false,
    required this.updatedAt,
    required this.createdAt,
  });

  String get cleanContent {
    if (content.isEmpty) return '';
    if (!content.trim().startsWith('{')) {
      return content;
    }

    try {
      final parsed = jsonDecode(content);
      final buffer = StringBuffer();

      void extractText(dynamic node) {
        if (node is Map) {
          final type = node['type'] as String?;

          if (type == 'image') {
            final attrs = node['attrs'] as Map?;
            final src = attrs?['src'] as String? ?? '';
            final alt = attrs?['alt'] as String? ?? 'Image';
            final width = attrs?['width'] as String? ?? '100%';
            final align = attrs?['align'] as String? ?? 'center';
            if (src.isNotEmpty) {
              buffer.write('\n![$alt|$width|$align]($src)\n');
            }
            return;
          }

          if (type == 'text' && node.containsKey('text')) {
            buffer.write(node['text']);
          }
          if (node.containsKey('content') && node['content'] is List) {
            final isBlock = type == 'paragraph' || type == 'heading' || type == 'codeBlock';
            for (final child in node['content']) {
              extractText(child);
            }
            if (isBlock) {
              buffer.write('\n');
            }
          }
        } else if (node is List) {
          for (final item in node) {
            extractText(item);
          }
        }
      }

      extractText(parsed);
      return buffer.toString().trim();
    } catch (_) {
      return content;
    }
  }

  String get plainTextSnippet {
    final text = cleanContent.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? 'No content yet…' : text;
  }

  static String encodeTipTapContent(String text) {
    if (text.isEmpty) {
      return jsonEncode({
        'type': 'doc',
        'content': [
          {'type': 'paragraph'}
        ],
      });
    }

    if (text.trim().startsWith('{')) {
      try {
        final parsed = jsonDecode(text);
        if (parsed is Map && parsed['type'] == 'doc') {
          return text;
        }
      } catch (_) {}
    }

    final lines = text.split('\n');
    final contentNodes = <Map<String, dynamic>>[];
    bool inCodeBlock = false;
    String codeBlockLang = '';
    final codeBlockLines = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // Check image syntax ![alt|width|align](src)
      final imgRegex = RegExp(r'^!\[(.*?)\]\((.*?)\)$');
      final imgMatch = imgRegex.firstMatch(trimmed);
      if (imgMatch != null) {
        final meta = imgMatch.group(1) ?? 'Image';
        final src = imgMatch.group(2);
        if (src != null && src.isNotEmpty) {
          final parts = meta.split('|');
          final alt = parts[0].isNotEmpty ? parts[0] : 'Image';
          final width = parts.length > 1 ? parts[1] : '100%';
          final align = parts.length > 2 ? parts[2] : 'center';

          contentNodes.add({
            'type': 'image',
            'attrs': {
              'src': src,
              'alt': alt,
              'width': width,
              'align': align,
            }
          });
          continue;
        }
      }

      if (trimmed.startsWith('```')) {
        if (inCodeBlock) {
          contentNodes.add({
            'type': 'codeBlock',
            'attrs': {'language': codeBlockLang},
            'content': [
              {'type': 'text', 'text': codeBlockLines.join('\n')}
            ]
          });
          inCodeBlock = false;
          codeBlockLines.clear();
          codeBlockLang = '';
        } else {
          inCodeBlock = true;
          codeBlockLang = trimmed.substring(3).trim();
        }
        continue;
      }

      if (inCodeBlock) {
        codeBlockLines.add(line);
        continue;
      }

      if (trimmed.startsWith('# ')) {
        contentNodes.add({
          'type': 'heading',
          'attrs': {'level': 1},
          'content': _parseInlineMarks(trimmed.substring(2))
        });
      } else if (trimmed.startsWith('## ')) {
        contentNodes.add({
          'type': 'heading',
          'attrs': {'level': 2},
          'content': _parseInlineMarks(trimmed.substring(3))
        });
      } else if (trimmed.startsWith('### ')) {
        contentNodes.add({
          'type': 'heading',
          'attrs': {'level': 3},
          'content': _parseInlineMarks(trimmed.substring(4))
        });
      } else if (trimmed.startsWith('> ')) {
        contentNodes.add({
          'type': 'blockquote',
          'content': [
            {
              'type': 'paragraph',
              'content': _parseInlineMarks(trimmed.substring(2))
            }
          ]
        });
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        contentNodes.add({
          'type': 'bulletList',
          'content': [
            {
              'type': 'listItem',
              'content': [
                {
                  'type': 'paragraph',
                  'content': _parseInlineMarks(trimmed.substring(2))
                }
              ]
            }
          ]
        });
      } else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        final match = RegExp(r'^\d+\.\s').firstMatch(trimmed);
        final itemText = trimmed.substring(match!.end);
        contentNodes.add({
          'type': 'orderedList',
          'content': [
            {
              'type': 'listItem',
              'content': [
                {
                  'type': 'paragraph',
                  'content': _parseInlineMarks(itemText)
                }
              ]
            }
          ]
        });
      } else if (trimmed.isEmpty) {
        contentNodes.add({'type': 'paragraph'});
      } else {
        contentNodes.add({
          'type': 'paragraph',
          'content': _parseInlineMarks(line)
        });
      }
    }

    if (inCodeBlock) {
      contentNodes.add({
        'type': 'codeBlock',
        'attrs': {'language': codeBlockLang},
        'content': [
          {'type': 'text', 'text': codeBlockLines.join('\n')}
        ]
      });
    }

    return jsonEncode({
      'type': 'doc',
      'content': contentNodes.isEmpty ? [{'type': 'paragraph'}] : contentNodes,
    });
  }

  static List<Map<String, dynamic>> _parseInlineMarks(String text) {
    if (text.isEmpty) return [];

    final result = <Map<String, dynamic>>[];
    final codeRegex = RegExp(r'`([^`]+)`');
    int lastEnd = 0;

    for (final match in codeRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        result.add({
          'type': 'text',
          'text': text.substring(lastEnd, match.start)
        });
      }
      result.add({
        'type': 'text',
        'text': match.group(1),
        'marks': [
          {'type': 'code'}
        ]
      });
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      result.add({
        'type': 'text',
        'text': text.substring(lastEnd)
      });
    }

    return result.isEmpty ? [{'type': 'text', 'text': text}] : result;
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    String? extractId(dynamic field) {
      if (field == null) return null;
      if (field is String) return field;
      if (field is Map && field.containsKey('_id')) return field['_id'].toString();
      return null;
    }

    return NoteModel(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      workspaceId: extractId(json['workspaceId']),
      folderId: extractId(json['folderId']),
      title: json['title'] ?? 'Untitled',
      content: json['content'] ?? '',
      slug: json['slug']?.toString(),
      tagIds: (json['tagIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isFavorite: json['isFavorite'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'workspaceId': workspaceId,
      'folderId': folderId,
      'title': title,
      'content': content,
      'slug': slug,
      'tagIds': tagIds,
      'isFavorite': isFavorite,
      'isDeleted': isDeleted,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NoteModel copyWith({
    String? title,
    String? content,
    bool? isFavorite,
    bool? isDeleted,
  }) {
    return NoteModel(
      id: id,
      userId: userId,
      workspaceId: workspaceId,
      folderId: folderId,
      title: title ?? this.title,
      content: content ?? this.content,
      slug: slug,
      tagIds: tagIds,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: DateTime.now(),
      createdAt: createdAt,
    );
  }
}

class FolderModel {
  final String id;
  final String name;
  final String workspaceId;
  final String? parentId;
  final String? icon;

  FolderModel({
    required this.id,
    required this.name,
    required this.workspaceId,
    this.parentId,
    this.icon,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      workspaceId: json['workspaceId']?.toString() ?? '',
      parentId: json['parentId']?.toString(),
      icon: json['icon']?.toString(),
    );
  }
}

class WorkspaceModel {
  final String id;
  final String name;
  final String? icon;

  WorkspaceModel({
    required this.id,
    required this.name,
    this.icon,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      icon: json['icon']?.toString(),
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String? bio;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar']?.toString(),
      bio: json['bio']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'bio': bio,
    };
  }
}

class TagModel {
  final String id;
  final String name;
  final String? color;
  final String? icon;

  TagModel({
    required this.id,
    required this.name,
    this.color,
    this.icon,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      color: json['color']?.toString() ?? '#f59e0b',
      icon: json['icon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'color': color,
      'icon': icon,
    };
  }
}
