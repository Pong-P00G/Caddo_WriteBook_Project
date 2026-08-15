import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tiptap_renderer.dart';
import '../providers/notes_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final NoteModel note;

  const NoteEditorScreen({super.key, required this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late bool _isFavorite;
  bool _isEditing = false;
  bool _isSaving = false;
  Timer? _debounceTimer;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.cleanContent);
    _isFavorite = widget.note.isFavorite;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    _debounceTimer?.cancel();
    setState(() => _isSaving = true);

    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      final formattedContent = NoteModel.encodeTipTapContent(_contentController.text);
      await ref.read(notesProvider.notifier).updateNote(
            widget.note.id,
            title: _titleController.text.trim(),
            content: formattedContent,
            isFavorite: _isFavorite,
          );
      if (mounted) {
        setState(() => _isSaving = false);
      }
    });
  }

  void _insertFormatting(String prefix, {String suffix = ''}) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isValid && selection.start != -1) {
      final start = selection.start;
      final end = selection.end;

      final selectedText = text.substring(start, end);
      final replacement = '$prefix$selectedText$suffix';

      final newText = text.replaceRange(start, end, replacement);
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + prefix.length + selectedText.length + suffix.length),
      );
    } else {
      final newText = '$text\n$prefix$suffix';
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
    _onContentChanged();
  }

  void _showInsertLinkDialog() {
    final urlController = TextEditingController();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'URL (https://example.com)',
                labelText: 'Link URL',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Display Text (optional)',
                labelText: 'Link Text',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              final displayText = textController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                final linkText = displayText.isNotEmpty ? displayText : url;
                _insertFormatting('[$linkText]($url)');
              }
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }

  void _showInsertImageDialog() {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image, color: AppColors.amber500),
              title: const Text('Pick from Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
                if (file != null) {
                  final bytes = await file.readAsBytes();
                  final base64Image = base64Encode(bytes);
                  final dataUrl = 'data:image/jpeg;base64,$base64Image';
                  _insertFormatting('![Image]($dataUrl)');
                }
              },
            ),
            const Divider(),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/image.jpg',
                labelText: 'Or Image URL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                _insertFormatting('![Image]($url)');
              }
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }

  void _insertTable() {
    const tableMarkdown = '''\n
| Header 1 | Header 2 | Header 3 |
| --- | --- | --- |
| Cell 1 | Cell 2 | Cell 3 |
| Cell 4 | Cell 5 | Cell 6 |
\n''';
    _insertFormatting(tableMarkdown);
  }

  void _deleteImageFromContent(String src) {
    final text = _contentController.text;
    final lines = text.split('\n');
    final updatedLines = lines.where((line) {
      final trimmed = line.trim();
      return !trimmed.contains(src);
    }).toList();

    _contentController.text = updatedLines.join('\n');
    _onContentChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image deleted from note'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEditImageModal(Map<String, dynamic> attrs) {
    final src = attrs['src'] as String? ?? '';
    final initialAlt = attrs['alt'] as String? ?? 'Image';
    final initialWidth = attrs['width'] as String? ?? '100%';
    final initialAlign = attrs['align'] as String? ?? 'center';

    final altController = TextEditingController(text: initialAlt);
    String selectedWidth = initialWidth;
    String selectedAlign = initialAlign;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Image Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Alt Text / Caption Input
                  TextField(
                    controller: altController,
                    decoration: const InputDecoration(
                      labelText: 'Alt Text / Caption',
                      hintText: 'Describe the image…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Size Selector
                  const Text(
                    'Size',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink400),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['25%', '50%', '75%', '100%'].map((w) {
                      final isSelected = selectedWidth == w;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: ChoiceChip(
                            label: Text(w, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            selectedColor: AppColors.amber500,
                            onSelected: (_) {
                              setModalState(() => selectedWidth = w);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Alignment Selector
                  const Text(
                    'Alignment',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.amber500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      {'label': 'Left', 'value': 'left', 'icon': LucideIcons.alignLeft},
                      {'label': 'Center', 'value': 'center', 'icon': LucideIcons.alignCenter},
                      {'label': 'Right', 'value': 'right', 'icon': LucideIcons.alignRight},
                    ].map((item) {
                      final val = item['value'] as String;
                      final isSelected = selectedAlign == val;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            avatar: Icon(item['icon'] as IconData, size: 14),
                            label: Text(item['label'] as String, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            selectedColor: AppColors.amber500,
                            onSelected: (_) {
                              setModalState(() => selectedAlign = val);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                          label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deleteImageFromContent(src);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(LucideIcons.check, size: 16),
                          label: const Text('Save Options'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateImageAttributes(
                              oldSrc: src,
                              alt: altController.text.trim(),
                              width: selectedWidth,
                              align: selectedAlign,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updateImageAttributes({
    required String oldSrc,
    required String alt,
    required String width,
    required String align,
  }) {
    final text = _contentController.text;
    final lines = text.split('\n');
    final updatedLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.contains(oldSrc) && trimmed.startsWith('![')) {
        updatedLines.add('![$alt|$width|$align]($oldSrc)');
      } else {
        updatedLines.add(line);
      }
    }

    _contentController.text = updatedLines.join('\n');
    _onContentChanged();
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    _onContentChanged();
  }

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber500),
                ),
              ),
            Text(
              _isSaving ? 'Saving…' : 'Saved',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.ink400 : AppColors.ink500,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Edit / View Mode Toggle Chip
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: ActionChip(
              avatar: Icon(
                _isEditing ? LucideIcons.eye : LucideIcons.pencil,
                size: 14,
                color: AppColors.amber500,
              ),
              label: Text(
                _isEditing ? 'View' : 'Edit',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amber500,
                ),
              ),
              backgroundColor: AppColors.amber500.withAlpha(25),
              side: BorderSide(color: AppColors.amber500.withAlpha(60)),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
                if (!_isEditing) {
                  _onContentChanged();
                }
              },
            ),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.star,
              size: 20,
              color: _isFavorite ? AppColors.amber500 : (isDark ? AppColors.ink500 : AppColors.ink400),
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.redAccent),
            onPressed: () async {
              await ref.read(notesProvider.notifier).deleteNote(widget.note.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing) ...[
                      TextField(
                        controller: _titleController,
                        onChanged: (_) => _onContentChanged(),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.ink900,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Untitled Note',
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contentController,
                        onChanged: (_) => _onContentChanged(),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: isDark ? AppColors.ink100 : AppColors.ink900,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Start writing your note…',
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ] else ...[
                      // Rich TipTap Rendered View Mode
                      Text(
                        _titleController.text.isEmpty ? 'Untitled Note' : _titleController.text,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TipTapRenderer(
                        contentJson: NoteModel.encodeTipTapContent(_contentController.text),
                        onDeleteImage: _deleteImageFromContent,
                        onEditImage: _showEditImageModal,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

            // Complete TipTap Formatting Toolbar (Visible when in Edit Mode)
            if (_isEditing)
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.ink900 : AppColors.ink100,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.ink800 : AppColors.ink200,
                    ),
                  ),
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    // Headings
                    IconButton(
                      icon: const Text('H1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.amber500)),
                      onPressed: () => _insertFormatting('# '),
                      tooltip: 'Heading 1',
                    ),
                    IconButton(
                      icon: const Text('H2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.amber500)),
                      onPressed: () => _insertFormatting('## '),
                      tooltip: 'Heading 2',
                    ),
                    IconButton(
                      icon: const Text('H3', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.amber500)),
                      onPressed: () => _insertFormatting('### '),
                      tooltip: 'Heading 3',
                    ),
                    const VerticalDivider(indent: 10, endIndent: 10, width: 12),

                    // Inline Styling (Bold, Italic, Underline, Strike)
                    IconButton(
                      icon: const Icon(LucideIcons.bold, size: 17, color: AppColors.amber500),
                      onPressed: () => _insertFormatting('**', suffix: '**'),
                      tooltip: 'Bold',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.italic, size: 17, color: AppColors.amber500),
                      onPressed: () => _insertFormatting('*', suffix: '*'),
                      tooltip: 'Italic',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.underline, size: 17, color: AppColors.amber500),
                      onPressed: () => _insertFormatting('<u>', suffix: '</u>'),
                      tooltip: 'Underline',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.strikethrough, size: 17, color: AppColors.amber500),
                      onPressed: () => _insertFormatting('~~', suffix: '~~'),
                      tooltip: 'Strikethrough',
                    ),
                    const VerticalDivider(indent: 10, endIndent: 10, width: 12),

                    // Lists
                    IconButton(
                      icon: const Icon(LucideIcons.list, size: 18, color: AppColors.amber500),
                      onPressed: () => _insertFormatting('- '),
                      tooltip: 'Bullet List',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.listOrdered, size: 18, color: AppColors.amber500),
                      onPressed: () => _insertFormatting('1. '),
                      tooltip: 'Numbered List',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.checkSquare, size: 18, color: AppColors.amber500),
                      onPressed: () => _insertFormatting('- [ ] '),
                      tooltip: 'Checklist',
                    ),
                    const VerticalDivider(indent: 10, endIndent: 10, width: 12),

                    // Code & Quote
                    IconButton(
                      icon: const Icon(LucideIcons.code2, size: 18, color: AppColors.amber500),
                      onPressed: () => _insertFormatting('```\n', suffix: '\n```'),
                      tooltip: 'Code Block',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.code, size: 18, color: AppColors.amber500),
                      onPressed: () => _insertFormatting('`', suffix: '`'),
                      tooltip: 'Inline Code',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.quote, size: 18, color: AppColors.amber500),
                      onPressed: () => _insertFormatting('> '),
                      tooltip: 'Quote',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.minus, size: 18, color: AppColors.amber500),
                      onPressed: () => _insertFormatting('\n---\n'),
                      tooltip: 'Divider',
                    ),
                    const VerticalDivider(indent: 10, endIndent: 10, width: 12),

                    // Rich Objects: Link, Image, Table
                    IconButton(
                      icon: const Icon(LucideIcons.link2, size: 18, color: AppColors.amber500),
                      onPressed: _showInsertLinkDialog,
                      tooltip: 'Insert Link',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.image, size: 18, color: AppColors.amber500),
                      onPressed: _showInsertImageDialog,
                      tooltip: 'Insert Image',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.table2, size: 18, color: AppColors.amber500),
                      onPressed: _insertTable,
                      tooltip: 'Insert Table',
                    ),
                  ],
                ),
              ),

            // Footer status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.ink800 : AppColors.ink200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_wordCount words',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.ink500 : AppColors.ink400,
                    ),
                  ),
                  Text(
                    '${_contentController.text.length} characters',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.ink500 : AppColors.ink400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
