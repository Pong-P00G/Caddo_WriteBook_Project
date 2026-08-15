import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/screens/profile_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/workspaces_provider.dart';
import '../providers/tags_provider.dart';
import '../providers/trash_provider.dart';
import 'note_editor_screen.dart';
import 'trash_screen.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  Widget _buildDrawerAvatarWidget(String? avatarUrl, String userInitials) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.amber500,
        child: Text(
          userInitials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    final resolved = ApiClient.resolveUrl(avatarUrl);
    if (resolved.startsWith('data:image/')) {
      try {
        final commaIndex = resolved.indexOf(',');
        if (commaIndex != -1) {
          final base64Str = resolved.substring(commaIndex + 1);
          final bytes = base64Decode(base64Str);
          return CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.amber500,
            backgroundImage: MemoryImage(bytes),
          );
        }
      } catch (_) {}
    }

    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.amber500,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            userInitials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Color _parseHexColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppColors.amber500;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.amber500;
    }
  }

  void _showAddWorkspaceDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Workspace'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Workspace Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                await ref.read(workspacesProvider.notifier).createWorkspace(controller.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context, WidgetRef ref, String? defaultWorkspaceId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                final wsId = defaultWorkspaceId ??
                    (ref.read(workspacesProvider).workspaces.isNotEmpty
                        ? ref.read(workspacesProvider).workspaces.first.id
                        : '');
                await ref.read(foldersProvider.notifier).createFolder(controller.text, wsId);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    String selectedColor = '#f59e0b';
    final colors = ['#f59e0b', '#3b82f6', '#10b981', '#ef4444', '#8b5cf6', '#ec4899'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Tag Name (e.g. code)'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: colors.map((hex) {
                  final color = Color(int.parse(hex.replaceFirst('#', '0xff')));
                  final isSelected = selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = hex),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withAlpha(150), blurRadius: 6)]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(ctx);
                  await ref.read(tagsProvider.notifier).createTag(controller.text, selectedColor);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteWorkspace(BuildContext context, WidgetRef ref, WorkspaceModel ws) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${ws.name}"?'),
        content: const Text(
          'Deleting this workspace will move all folders and notes inside it to the Trash.',
        ),
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
              final success = await ref.read(workspacesProvider.notifier).deleteWorkspace(ws.id);
              if (success) {
                ref.read(notesProvider.notifier).fetchNotes();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Workspace "${ws.name}" deleted')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(BuildContext context, WidgetRef ref, FolderModel folder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${folder.name}"?'),
        content: const Text(
          'Deleting this folder will move all notes inside it to the Trash.',
        ),
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
              final success = await ref.read(foldersProvider.notifier).deleteFolder(folder.id);
              if (success) {
                ref.read(notesProvider.notifier).fetchNotes();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Folder "${folder.name}" deleted')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);
    final notifier = ref.read(notesProvider.notifier);
    final authState = ref.watch(authProvider);
    final workspacesState = ref.watch(workspacesProvider);
    final foldersState = ref.watch(foldersProvider);
    final tagsState = ref.watch(tagsProvider);
    final trashState = ref.watch(trashProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = authState.user;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth >= 850;
    final int crossAxisCount = screenWidth > 1200 ? 4 : (screenWidth > 850 ? 3 : 2);

    final userInitials = (user?.name.isNotEmpty == true)
        ? user!.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'WB';

    final filteredNotes = state.notes.where((note) {
      if (state.activeTab == 'favorites' && !note.isFavorite) return false;
      return true;
    }).toList();

    Widget buildDrawerContent({required bool isPermanent}) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Header
            InkWell(
              onTap: () {
                if (!isPermanent) Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.ink900 : Colors.amber.shade50.withAlpha(120),
                ),
                child: Row(
                  children: [
                    _buildDrawerAvatarWidget(user?.avatar, userInitials),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'WriteBook User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.ink400 : AppColors.ink600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.ink400),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Navigation Content Scroll View
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.fileText, size: 20),
                    title: const Text('All Notes'),
                    selected: state.activeTab == 'all' &&
                        foldersState.selectedFolderId == null &&
                        workspacesState.selectedWorkspaceId == null &&
                        tagsState.selectedTagId == null,
                    onTap: () {
                      ref.read(foldersProvider.notifier).selectFolder(null);
                      ref.read(workspacesProvider.notifier).selectWorkspace(null);
                      ref.read(tagsProvider.notifier).selectTag(null);
                      notifier.fetchNotes(folderId: '', workspaceId: '', tagId: '');
                      notifier.setActiveTab('all');
                      if (!isPermanent) Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.star, size: 20, color: AppColors.amber500),
                    title: const Text('Favorites'),
                    selected: state.activeTab == 'favorites',
                    onTap: () {
                      notifier.setActiveTab('favorites');
                      if (!isPermanent) Navigator.pop(context);
                    },
                  ),

                  // WORKSPACES SECTION
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'WORKSPACES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.ink400,
                          ),
                        ),
                        InkWell(
                          onTap: () => _showAddWorkspaceDialog(context, ref),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(LucideIcons.plus, size: 16, color: AppColors.ink400),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...workspacesState.workspaces.map((ws) {
                    final isSelected = workspacesState.selectedWorkspaceId == ws.id;
                    return ListTile(
                      dense: true,
                      leading: const Icon(LucideIcons.layoutGrid, size: 16),
                      title: Text(ws.name),
                      selected: isSelected,
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.ink400),
                        splashRadius: 16,
                        onPressed: () => _confirmDeleteWorkspace(context, ref, ws),
                        tooltip: 'Delete workspace',
                      ),
                      onTap: () {
                        ref.read(workspacesProvider.notifier).selectWorkspace(ws.id);
                        ref.read(foldersProvider.notifier).selectFolder(null);
                        ref.read(tagsProvider.notifier).selectTag(null);
                        notifier.fetchNotes(workspaceId: ws.id, folderId: '', tagId: '');
                        if (!isPermanent) Navigator.pop(context);
                      },
                    );
                  }),

                  // FOLDERS SECTION
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FOLDERS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.ink400,
                          ),
                        ),
                        InkWell(
                          onTap: () => _showAddFolderDialog(
                              context, ref, workspacesState.selectedWorkspaceId),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(LucideIcons.plus, size: 16, color: AppColors.ink400),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...foldersState.folders.map((folder) {
                    final isSelected = foldersState.selectedFolderId == folder.id;
                    return ListTile(
                      dense: true,
                      leading: const Icon(LucideIcons.folder, size: 16),
                      title: Text(folder.name),
                      selected: isSelected,
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.ink400),
                        splashRadius: 16,
                        onPressed: () => _confirmDeleteFolder(context, ref, folder),
                        tooltip: 'Delete folder',
                      ),
                      onTap: () {
                        ref.read(foldersProvider.notifier).selectFolder(folder.id);
                        ref.read(workspacesProvider.notifier).selectWorkspace(null);
                        ref.read(tagsProvider.notifier).selectTag(null);
                        notifier.fetchNotes(folderId: folder.id, workspaceId: '', tagId: '');
                        if (!isPermanent) Navigator.pop(context);
                      },
                    );
                  }),

                  // TAGS SECTION
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TAGS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.ink400,
                          ),
                        ),
                        InkWell(
                          onTap: () => _showAddTagDialog(context, ref),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(LucideIcons.plus, size: 16, color: AppColors.ink400),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tagsState.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tagsState.tags.map((tag) {
                          final isSelected = tagsState.selectedTagId == tag.id;
                          final tagColor = _parseHexColor(tag.color);
                          return FilterChip(
                            label: Text(
                              '# ${tag.name}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.ink200 : AppColors.ink800),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: tagColor,
                            backgroundColor: tagColor.withAlpha(35),
                            side: BorderSide(
                              color: isSelected ? tagColor : tagColor.withAlpha(80),
                            ),
                            onSelected: (_) {
                              ref.read(tagsProvider.notifier).selectTag(isSelected ? null : tag.id);
                              ref.read(foldersProvider.notifier).selectFolder(null);
                              ref.read(workspacesProvider.notifier).selectWorkspace(null);
                              notifier.fetchNotes(
                                tagId: isSelected ? '' : tag.id,
                                folderId: '',
                                workspaceId: '',
                              );
                              if (!isPermanent) Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),

                  const Divider(),

                  // TRASH & SETTINGS
                  ListTile(
                    leading: const Icon(LucideIcons.trash2, size: 20),
                    title: const Text('Trash Bin'),
                    trailing: trashState.notes.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${trashState.notes.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      if (!isPermanent) Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TrashScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.settings, size: 20),
                    title: const Text('Settings'),
                    onTap: () {
                      if (!isPermanent) Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget mainNotesBody = Column(
      children: [
        // Search & Filter header bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                onChanged: (val) => notifier.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Search notes…',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  filled: true,
                  fillColor: isDark ? AppColors.ink900 : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.ink800 : AppColors.ink200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.ink800 : AppColors.ink200,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${filteredNotes.length} notes',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.ink400 : AppColors.ink500,
                    ),
                  ),
                  const Spacer(),
                  ChoiceChip(
                    label: const Text('All'),
                    selected: state.activeTab == 'all',
                    onSelected: (_) => notifier.setActiveTab('all'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Favorites'),
                    selected: state.activeTab == 'favorites',
                    onSelected: (_) => notifier.setActiveTab('favorites'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Content body
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.amber500))
              : state.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to fetch notes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.ink900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.ink400),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => notifier.fetchNotes(),
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : filteredNotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.stickyNote,
                                size: 48,
                                color: isDark ? AppColors.ink700 : AppColors.ink300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No notes found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.ink300 : AppColors.ink600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => notifier.fetchNotes(),
                          child: state.isGridView
                              ? GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemCount: filteredNotes.length,
                                  itemBuilder: (context, index) {
                                    final note = filteredNotes[index];
                                    return _NoteGridCard(
                                      note: note,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => NoteEditorScreen(note: note),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: filteredNotes.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final note = filteredNotes[index];
                                    return _NoteListCard(
                                      note: note,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => NoteEditorScreen(note: note),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('WriteBook Notes'),
        automaticallyImplyLeading: !isWideScreen,
        actions: [
          IconButton(
            icon: Icon(
              state.isGridView ? LucideIcons.list : LucideIcons.layoutGrid,
              size: 20,
            ),
            onPressed: () => notifier.toggleViewMode(),
          ),
        ],
      ),
      drawer: isWideScreen
          ? null
          : Drawer(
              backgroundColor: isDark ? AppColors.ink950 : Colors.white,
              child: buildDrawerContent(isPermanent: false),
            ),
      body: isWideScreen
          ? Row(
              children: [
                // Permanent Responsive Left Navigation Sidebar
                Container(
                  width: 270,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.ink950 : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? AppColors.ink800 : AppColors.ink200,
                      ),
                    ),
                  ),
                  child: buildDrawerContent(isPermanent: true),
                ),
                // Main Notes Content Panel
                Expanded(
                  child: mainNotesBody,
                ),
              ],
            )
          : mainNotesBody,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.amber500,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: const Text('New Note'),
        onPressed: () async {
          final newNote = await notifier.createNote(title: 'Untitled Note');
          if (newNote != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteEditorScreen(note: newNote),
              ),
            );
          }
        },
      ),
    );
  }
}

class _NoteGridCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;

  const _NoteGridCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('MMM d').format(note.updatedAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.ink900 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.ink800 : AppColors.ink200.withAlpha(204),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withAlpha(77) : Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.ink900,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (note.isFavorite)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.amber500.withAlpha(38),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.star,
                        size: 13,
                        color: AppColors.amber500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  note.plainTextSnippet,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? AppColors.ink400 : AppColors.ink600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.ink950 : AppColors.ink100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.ink400 : AppColors.ink600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteListCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;

  const _NoteListCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('MMM d').format(note.updatedAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.ink900 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.ink800 : AppColors.ink200.withAlpha(204),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withAlpha(77) : Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'Untitled' : note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : AppColors.ink900,
                            ),
                          ),
                        ),
                        if (note.isFavorite)
                          Container(
                            margin: const EdgeInsets.only(left: 6, right: 8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.amber500.withAlpha(38),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.star,
                              size: 13,
                              color: AppColors.amber500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      note.plainTextSnippet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.ink400 : AppColors.ink600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.ink950 : AppColors.ink100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.ink400 : AppColors.ink600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
