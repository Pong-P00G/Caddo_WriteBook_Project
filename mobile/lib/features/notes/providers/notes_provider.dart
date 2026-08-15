import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';

class NotesState {
  final List<NoteModel> notes;
  final bool isLoading;
  final String? error;
  final bool isGridView;
  final String searchQuery;
  final String activeTab; // 'all' or 'favorites'

  NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
    this.isGridView = true,
    this.searchQuery = '',
    this.activeTab = 'all',
  });

  NotesState copyWith({
    List<NoteModel>? notes,
    bool? isLoading,
    String? error,
    bool? isGridView,
    String? searchQuery,
    String? activeTab,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isGridView: isGridView ?? this.isGridView,
      searchQuery: searchQuery ?? this.searchQuery,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  final ApiClient _api = ApiClient();

  NotesNotifier() : super(NotesState()) {
    fetchNotes();
  }

  String? _currentFolderId;
  String? _currentWorkspaceId;
  String? _currentTagId;

  Future<void> fetchNotes({String? search, String? folderId, String? workspaceId, String? tagId}) async {
    if (folderId != null) _currentFolderId = folderId.isEmpty ? null : folderId;
    if (workspaceId != null) _currentWorkspaceId = workspaceId.isEmpty ? null : workspaceId;
    if (tagId != null) _currentTagId = tagId.isEmpty ? null : tagId;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.get('/notes', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (_currentFolderId != null && _currentFolderId!.isNotEmpty) 'folderId': _currentFolderId,
        if (_currentWorkspaceId != null && _currentWorkspaceId!.isNotEmpty) 'workspaceId': _currentWorkspaceId,
      });

      if (response.data['success'] == true) {
        final rawList = response.data['data'] as List;
        var notes = rawList.map((e) => NoteModel.fromJson(e)).toList();
        if (_currentTagId != null && _currentTagId!.isNotEmpty) {
          notes = notes.where((n) => n.tagIds.contains(_currentTagId)).toList();
        }
        state = state.copyWith(notes: notes, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: response.data['error'] ?? 'Failed to load notes');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void toggleViewMode() {
    state = state.copyWith(isGridView: !state.isGridView);
  }

  void setActiveTab(String tab) {
    state = state.copyWith(activeTab: tab);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    fetchNotes(search: query);
  }

  Future<NoteModel?> createNote({String title = 'Untitled', String content = ''}) async {
    try {
      final formattedContent = NoteModel.encodeTipTapContent(content);
      final response = await _api.dio.post('/notes', data: {
        'title': title,
        'content': formattedContent,
      });

      if (response.data['success'] == true) {
        final newNote = NoteModel.fromJson(response.data['data']);
        state = state.copyWith(notes: [newNote, ...state.notes]);
        return newNote;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return null;
  }

  Future<void> updateNote(String id, {String? title, String? content, bool? isFavorite}) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (content != null) data['content'] = content;
      if (isFavorite != null) data['isFavorite'] = isFavorite;

      final response = await _api.dio.patch('/notes/$id', data: data);

      if (response.data['success'] == true) {
        final updated = NoteModel.fromJson(response.data['data']);
        final updatedList = state.notes.map((n) => n.id == id ? updated : n).toList();
        state = state.copyWith(notes: updatedList);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      final response = await _api.dio.delete('/notes/$id');
      if (response.data['success'] == true) {
        final updatedList = state.notes.where((n) => n.id != id).toList();
        state = state.copyWith(notes: updatedList);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  return NotesNotifier();
});
