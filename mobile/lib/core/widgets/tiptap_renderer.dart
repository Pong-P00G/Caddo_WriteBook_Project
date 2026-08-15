import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../api/api_client.dart';
import '../theme/app_theme.dart';

class TipTapRenderer extends StatelessWidget {
  final String contentJson;
  final void Function(String src)? onDeleteImage;
  final void Function(Map<String, dynamic> attrs)? onEditImage;

  const TipTapRenderer({
    super.key,
    required this.contentJson,
    this.onDeleteImage,
    this.onEditImage,
  });

  Color _parseHexColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.yellow;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.yellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (contentJson.isEmpty) {
      return const Text(
        'No content yet…',
        style: TextStyle(color: AppColors.ink400, fontSize: 15),
      );
    }

    try {
      dynamic parsed;
      if (contentJson.trim().startsWith('{')) {
        parsed = jsonDecode(contentJson);
      } else {
        return SelectableText(
          contentJson,
          style: const TextStyle(fontSize: 15, height: 1.6),
        );
      }

      if (parsed is Map && parsed['type'] == 'doc') {
        final content = parsed['content'] as List?;
        if (content == null || content.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content.map((node) => _buildNode(context, node)).toList(),
        );
      }
    } catch (_) {}

    return SelectableText(
      contentJson,
      style: const TextStyle(fontSize: 15, height: 1.6),
    );
  }

  Widget _buildNode(BuildContext context, dynamic node) {
    if (node is! Map) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = node['type'] as String?;

    switch (type) {
      case 'image':
        final attrs = (node['attrs'] as Map?)?.cast<String, dynamic>() ?? {};
        final src = attrs['src'] as String?;
        if (src == null || src.isEmpty) return const SizedBox.shrink();

        final widthStr = attrs['width'] as String? ?? '100%';
        final alignStr = attrs['align'] as String? ?? 'center';

        double widthFactor = 1.0;
        if (widthStr == '25%') widthFactor = 0.25;
        if (widthStr == '50%') widthFactor = 0.50;
        if (widthStr == '75%') widthFactor = 0.75;

        Alignment alignment = Alignment.center;
        if (alignStr == 'left') alignment = Alignment.centerLeft;
        if (alignStr == 'right') alignment = Alignment.centerRight;

        Widget imageWidget;
        if (src.startsWith('data:image/')) {
          try {
            final commaIndex = src.indexOf(',');
            if (commaIndex != -1) {
              final base64Str = src.substring(commaIndex + 1);
              final bytes = base64Decode(base64Str);
              imageWidget = Image.memory(bytes, fit: BoxFit.contain);
            } else {
              return const SizedBox.shrink();
            }
          } catch (_) {
            return const SizedBox.shrink();
          }
        } else {
          final resolvedUrl = ApiClient.resolveUrl(src);
          imageWidget = Image.network(
            resolvedUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? AppColors.ink900 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(LucideIcons.imageOff, size: 24, color: AppColors.ink400),
                  SizedBox(height: 4),
                  Text(
                    'Image failed to load',
                    style: TextStyle(fontSize: 12, color: AppColors.ink400),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          alignment: alignment,
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.ink800 : AppColors.ink200,
                ),
              ),
              child: Stack(
                children: [
                  imageWidget,
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEditImage != null) ...[
                          Material(
                            color: Colors.black.withAlpha(180),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => onEditImage?.call(attrs),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.pencil,
                                      size: 14,
                                      color: AppColors.amber500,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (onDeleteImage != null)
                          Material(
                            color: Colors.black.withAlpha(180),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => onDeleteImage?.call(src),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.trash2,
                                      size: 14,
                                      color: Colors.redAccent,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case 'heading':
        final attrs = node['attrs'] as Map?;
        final level = attrs?['level'] as int? ?? 1;
        double fontSize = 24;
        if (level == 2) fontSize = 20;
        if (level == 3) fontSize = 18;

        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: SelectableText.rich(
            TextSpan(
              children: _buildInlineContent(context, node['content']),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.ink900,
                height: 1.3,
              ),
            ),
          ),
        );

      case 'paragraph':
        final inline = _buildInlineContent(context, node['content']);
        if (inline.isEmpty) {
          return const SizedBox(height: 12);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SelectableText.rich(
            TextSpan(
              children: inline,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: isDark ? AppColors.ink100 : AppColors.ink900,
              ),
            ),
          ),
        );

      case 'bulletList':
        final items = node['content'] as List?;
        if (items == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => _buildListItem(context, item, isOrdered: false)).toList(),
          ),
        );

      case 'orderedList':
        final items = node['content'] as List?;
        if (items == null) return const SizedBox.shrink();

        int index = 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => _buildListItem(context, item, isOrdered: true, index: index++)).toList(),
          ),
        );

      case 'codeBlock':
        final language = (node['attrs'] as Map?)?['language'] as String?;
        final codeText = _getNodeText(node);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.ink900 : Colors.grey.shade900,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.ink800 : Colors.grey.shade800,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (language != null && language.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    language.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.amber500,
                    ),
                  ),
                ),
              SelectableText(
                codeText,
                style: GoogleFonts.firaCode(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.amber.shade100,
                ),
              ),
            ],
          ),
        );

      case 'blockquote':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.amber500, width: 3),
            ),
          ),
          child: SelectableText.rich(
            TextSpan(
              children: _buildInlineContent(context, node['content']),
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.ink300 : AppColors.ink600,
              ),
            ),
          ),
        );

      case 'taskList':
        final items = node['content'] as List?;
        if (items == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => _buildTaskItem(context, item)).toList(),
          ),
        );

      case 'horizontalRule':
        return Divider(
          height: 24,
          color: isDark ? AppColors.ink800 : AppColors.ink200,
        );

      case 'table':
        final rows = node['content'] as List?;
        if (rows == null || rows.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.ink800 : AppColors.ink200,
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(
                color: isDark ? AppColors.ink800 : AppColors.ink200,
                width: 1,
              ),
              children: rows.map<TableRow>((row) {
                if (row is! Map) return const TableRow(children: []);
                final cells = row['content'] as List?;
                if (cells == null) return const TableRow(children: []);

                return TableRow(
                  children: cells.map<Widget>((cell) {
                    if (cell is! Map) return const SizedBox.shrink();
                    final isHeader = cell['type'] == 'table_header';

                    return Container(
                      padding: const EdgeInsets.all(10),
                      color: isHeader
                          ? (isDark ? AppColors.ink800 : AppColors.ink100)
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (cell['content'] as List?)
                                ?.map((c) => _buildNode(context, c))
                                .toList() ??
                            [const SizedBox.shrink()],
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        );

      default:
        final inline = _buildInlineContent(context, node['content']);
        if (inline.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SelectableText.rich(TextSpan(children: inline)),
        );
    }
  }

  Widget _buildListItem(BuildContext context, dynamic item, {required bool isOrdered, int index = 1}) {
    if (item is! Map) return const SizedBox.shrink();

    final content = item['content'] as List?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              isOrdered ? '$index.' : '•',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.amber500,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content != null
                  ? content.map((child) => _buildNode(context, child)).toList()
                  : [const SizedBox.shrink()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, dynamic item) {
    if (item is! Map) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final checked = (item['attrs'] as Map?)?['checked'] == true;
    final content = item['content'] as List?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            checked ? LucideIcons.checkSquare : LucideIcons.square,
            size: 18,
            color: checked ? AppColors.amber500 : (isDark ? AppColors.ink500 : AppColors.ink400),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content != null
                  ? content.map((child) => _buildNode(context, child)).toList()
                  : [const SizedBox.shrink()],
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildInlineContent(BuildContext context, dynamic contentList) {
    if (contentList is! List) return [];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spans = <InlineSpan>[];

    for (final inline in contentList) {
      if (inline is! Map) continue;

      final type = inline['type'] as String?;
      if (type == 'text') {
        final text = inline['text'] as String? ?? '';
        final marks = inline['marks'] as List?;

        TextStyle style = TextStyle(
          fontSize: 15,
          color: isDark ? AppColors.ink100 : AppColors.ink900,
        );

        bool isCodeMark = false;

        if (marks != null) {
          for (final mark in marks) {
            if (mark is! Map) continue;
            final markType = mark['type'] as String?;
            switch (markType) {
              case 'bold':
                style = style.copyWith(fontWeight: FontWeight.bold);
                break;
              case 'italic':
                style = style.copyWith(fontStyle: FontStyle.italic);
                break;
              case 'underline':
                style = style.copyWith(decoration: TextDecoration.underline);
                break;
              case 'highlight':
                final attrs = mark['attrs'] as Map?;
                final colorHex = attrs?['color'] as String? ?? '#ffff00';
                final highlightColor = _parseHexColor(colorHex);
                style = style.copyWith(backgroundColor: highlightColor.withAlpha(120));
                break;
              case 'subscript':
              case 'superscript':
                style = style.copyWith(fontSize: 11);
                break;
              case 'code':
                isCodeMark = true;
                break;
              case 'link':
                style = style.copyWith(
                  color: AppColors.amber500,
                  decoration: TextDecoration.underline,
                );
                break;
            }
          }
        }

        if (isCodeMark) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.ink800 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  text,
                  style: GoogleFonts.firaCode(
                    fontSize: 13,
                    color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                  ),
                ),
              ),
            ),
          );
        } else {
          spans.add(TextSpan(text: text, style: style));
        }
      } else if (type == 'hardBreak') {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  String _getNodeText(dynamic node) {
    if (node is! Map) return '';
    final buffer = StringBuffer();

    void walk(dynamic n) {
      if (n is Map) {
        if (n['type'] == 'text' && n.containsKey('text')) {
          buffer.write(n['text']);
        }
        if (n.containsKey('content') && n['content'] is List) {
          for (final child in n['content']) {
            walk(child);
          }
        }
      } else if (n is List) {
        for (final item in n) {
          walk(item);
        }
      }
    }

    walk(node['content']);
    return buffer.toString();
  }
}
