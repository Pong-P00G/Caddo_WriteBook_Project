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
    String result;

    if (!content.trim().startsWith('{')) {
      result = content;
    } else {
      try {
        dynamic parsed = jsonDecode(content);

        // Unwrap any nested or double-encoded doc
        while (parsed is Map &&
            parsed['type'] == 'doc' &&
            parsed['content'] is List &&
            (parsed['content'] as List).length == 1 &&
            (parsed['content'] as List)[0] is Map &&
            (parsed['content'] as List)[0]['type'] == 'paragraph' &&
            (parsed['content'] as List)[0]['content'] is List &&
            ((parsed['content'] as List)[0]['content'] as List).length == 1 &&
            ((parsed['content'] as List)[0]['content'] as List)[0] is Map &&
            ((parsed['content'] as List)[0]['content'] as List)[0]['text'] is String &&
            (((parsed['content'] as List)[0]['content'] as List)[0]['text'] as String).trim().startsWith('{"type":"doc"')) {
          try {
            parsed = jsonDecode((((parsed['content'] as List)[0]['content'] as List)[0]['text'] as String).trim());
          } catch (_) {
            break;
          }
        }

        final buffer = StringBuffer();

        void extractText(dynamic node, {bool insideList = false}) {
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

            if (type == 'heading') {
              final level = (node['attrs'] as Map?)?['level'] as int? ?? 1;
              buffer.write('${'#' * level} ');
            } else if (type == 'blockquote') {
              buffer.write('> ');
            } else if (type == 'listItem') {
              buffer.write('- ');
            } else if (type == 'taskItem') {
              final checked = (node['attrs'] as Map?)?['checked'] == true;
              buffer.write(checked ? '- [x] ' : '- [ ] ');
            }

            if (type == 'text' && node.containsKey('text')) {
              buffer.write(node['text'] ?? '');
            }

            if (node.containsKey('content') && node['content'] is List) {
              final isList = type == 'listItem' || type == 'taskItem' || insideList;
              final isBlock = type == 'paragraph' ||
                  type == 'heading' ||
                  type == 'codeBlock' ||
                  type == 'listItem' ||
                  type == 'taskItem';
              for (final child in node['content']) {
                extractText(child, insideList: type == 'listItem' || type == 'taskItem');
              }
              if (isBlock && !(type == 'paragraph' && isList)) {
                buffer.write('\n');
              }
            }
          } else if (node is List) {
            for (final item in node) {
              extractText(item, insideList: insideList);
            }
          }
        }

        extractText(parsed);
        result = buffer.toString().trim();
      } catch (_) {
        result = content;
      }
    }

    // Strip any raw leftover HTML formatting tags so editor & snippets stay clean
    result = result
        .replaceAll(RegExp(r'</?(?:color|mark|span|u)(?:\s+[^>]*)?>', caseSensitive: false), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return result;
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
        dynamic parsed = jsonDecode(text);
        // Unwrap any nested or double-encoded doc
        while (parsed is Map &&
            parsed['type'] == 'doc' &&
            parsed['content'] is List &&
            (parsed['content'] as List).length == 1 &&
            (parsed['content'] as List)[0] is Map &&
            (parsed['content'] as List)[0]['type'] == 'paragraph' &&
            (parsed['content'] as List)[0]['content'] is List &&
            ((parsed['content'] as List)[0]['content'] as List).length == 1 &&
            ((parsed['content'] as List)[0]['content'] as List)[0] is Map &&
            ((parsed['content'] as List)[0]['content'] as List)[0]['text'] is String &&
            (((parsed['content'] as List)[0]['content'] as List)[0]['text'] as String).trim().startsWith('{"type":"doc"')) {
          try {
            parsed = jsonDecode((((parsed['content'] as List)[0]['content'] as List)[0]['text'] as String).trim());
          } catch (_) {
            break;
          }
        }
        if (parsed is Map && parsed['type'] == 'doc') {
          return jsonEncode(parsed);
        }
      } catch (_) {}
    }

    // Sanitize any raw HTML marks out of text before parsing lines
    final sanitizedText = text
        .replaceAll(RegExp(r'</?(?:color|mark|span|u)(?:\s+[^>]*)?>', caseSensitive: false), '');

    final lines = sanitizedText.split('\n');
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
      } else if (trimmed.startsWith('- [ ] ') || trimmed.startsWith('- [x] ') || trimmed.startsWith('- [X] ')) {
        final checked = trimmed.startsWith('- [x] ') || trimmed.startsWith('- [X] ');
        final itemText = trimmed.substring(6);
        contentNodes.add({
          'type': 'taskList',
          'content': [
            {
              'type': 'taskItem',
              'attrs': {'checked': checked},
              'content': [
                {
                  'type': 'paragraph',
                  'content': _parseInlineMarks(itemText)
                }
              ]
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

    // Regular expressions for inline tokens
    final tokenRegex = RegExp(
      r'(`[^`]+`)|' // 1: code
      r'(\[([^\]]+)\]\(([^)]+)\))|' // 2: link [text](url), 3: text, 4: url
      r'(<span\s+style="color:\s*([^"]+)">([\s\S]*?)<\/span>)|' // 5: colored span, 6: color, 7: text
      r'(<color=([^>]+)>([\s\S]*?)<\/color>)|' // 8: color tag, 9: color, 10: text
      r'(<mark(?:\s+style="background-color:\s*([^"]+)")?>([\s\S]*?)<\/mark>)|' // 11: mark tag, 12: color, 13: text
      r'(==([^=]+)==)|' // 14: highlight ==text==, 15: text
      r'(\*\*([^*]+)\*\*)|' // 16: bold **text**, 17: text
      r'(\*([^*]+)\*)|' // 18: italic *text*, 19: text
      r'(~~([^~]+)~~)|' // 20: strike ~~text~~, 21: text
      r'(<u>([\s\S]*?)<\/u>)', // 22: underline <u>text</u>, 23: text
    );

    final result = <Map<String, dynamic>>[];
    int lastEnd = 0;

    for (final match in tokenRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        result.add({
          'type': 'text',
          'text': text.substring(lastEnd, match.start),
        });
      }

      if (match.group(1) != null) {
        // Code
        final codeText = match.group(1)!.substring(1, match.group(1)!.length - 1);
        result.add({
          'type': 'text',
          'text': codeText,
          'marks': [{'type': 'code'}],
        });
      } else if (match.group(2) != null) {
        // Link
        final linkText = match.group(3) ?? '';
        final url = match.group(4) ?? '';
        result.add({
          'type': 'text',
          'text': linkText,
          'marks': [
            {
              'type': 'link',
              'attrs': {'href': url, 'target': '_blank'},
            }
          ],
        });
      } else if (match.group(5) != null) {
        // Colored span
        final color = match.group(6)?.trim() ?? '#000000';
        final inner = match.group(7) ?? '';
        result.add({
          'type': 'text',
          'text': inner,
          'marks': [
            {
              'type': 'textStyle',
              'attrs': {'color': color},
            }
          ],
        });
      } else if (match.group(8) != null) {
        // <color=...> tag
        final color = match.group(9)?.trim() ?? '#000000';
        final inner = match.group(10) ?? '';
        result.add({
          'type': 'text',
          'text': inner,
          'marks': [
            {
              'type': 'textStyle',
              'attrs': {'color': color},
            }
          ],
        });
      } else if (match.group(11) != null) {
        // <mark> tag
        final color = match.group(12)?.trim() ?? '#fef08a';
        final inner = match.group(13) ?? '';
        result.add({
          'type': 'text',
          'text': inner,
          'marks': [
            {
              'type': 'highlight',
              'attrs': {'color': color},
            }
          ],
        });
      } else if (match.group(14) != null) {
        // ==highlight==
        final inner = match.group(15) ?? '';
        result.add({
          'type': 'text',
          'text': inner,
          'marks': [
            {
              'type': 'highlight',
              'attrs': {'color': '#fef08a'},
            }
          ],
        });
      } else if (match.group(16) != null) {
        // **bold**
        final inner = match.group(17) ?? '';
        result.add({
          'type': 'text',
          'text': inner,
          'marks': [{'type': 'bold'}],
        });
      } else if (match.group(18) != null) {
        // *italic*
        final inner = match.group(19) ?? '';
        result.add({
          'type': 'text',
          'text': inner,
          'marks': [{'type': 'italic'}],
        });
      } else if (match.group(20) != null) {
        // ~~strike~~
        final inner = match.group(21) ?? '';
        result.add({
          'type': 'text',
          'text': inner,
          'marks': [{'type': 'strike'}],
        });
      } else if (match.group(22) != null) {
        // <u>underline</u>
        final inner = match.group(23) ?? '';
        result.add({
          'type': 'text',
          'text': inner,
          'marks': [{'type': 'underline'}],
        });
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      result.add({
        'type': 'text',
        'text': text.substring(lastEnd),
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
