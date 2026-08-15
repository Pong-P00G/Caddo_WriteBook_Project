import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/trash_provider.dart';
import '../providers/notes_provider.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashState = ref.watch(trashProvider);
    final trashNotifier = ref.read(trashProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Trash Bin'),
      ),
      body: SafeArea(
        child: trashState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.amber500))
            : trashState.notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.trash2,
                          size: 48,
                          color: isDark ? AppColors.ink700 : AppColors.ink300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Trash is empty',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.ink300 : AppColors.ink600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Deleted notes will appear here',
                          style: TextStyle(fontSize: 13, color: AppColors.ink400),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => trashNotifier.fetchTrashNotes(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: trashState.notes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final note = trashState.notes[index];
                        final dateStr = DateFormat('MMM d, yyyy').format(note.updatedAt);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.ink900 : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.ink800 : AppColors.ink200.withAlpha(204),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      note.title.isEmpty ? 'Untitled' : note.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.ink900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.ink400,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                note.plainTextSnippet,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.ink400 : AppColors.ink600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Restore Button
                                  OutlinedButton.icon(
                                    icon: const Icon(LucideIcons.undo, size: 14),
                                    label: const Text('Restore'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.amber500,
                                      side: const BorderSide(color: AppColors.amber500),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    onPressed: () async {
                                      final success = await trashNotifier.restoreNote(note.id);
                                      if (success) {
                                        ref.read(notesProvider.notifier).fetchNotes();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Note restored'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  // Delete Permanently Button
                                  TextButton.icon(
                                    icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                                    label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete Permanently?'),
                                          content: const Text('This action cannot be undone.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.redAccent,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () async {
                                                Navigator.pop(ctx);
                                                await trashNotifier.permanentDeleteNote(note.id);
                                              },
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
