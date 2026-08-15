import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';

class TrashState {
  final List<NoteModel> notes;
  final bool isLoading;
  final String? error;

  TrashState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
  });

  TrashState copyWith({
    List<NoteModel>? notes,
    bool? isLoading,
    String? error,
  }) {
    return TrashState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TrashNotifier extends StateNotifier<TrashState> {
  final ApiClient _api = ApiClient();

  TrashNotifier() : super(TrashState()) {
    fetchTrashNotes();
  }

  Future<void> fetchTrashNotes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.get('/notes/trash');
      if (response.data['success'] == true) {
        final rawList = response.data['data'] as List;
        final notes = rawList.map((e) => NoteModel.fromJson(e)).toList();
        state = state.copyWith(notes: notes, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load trash notes');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> restoreNote(String noteId) async {
    try {
      final response = await _api.dio.post('/notes/$noteId/restore');
      if (response.data['success'] == true) {
        state = state.copyWith(
          notes: state.notes.where((n) => n.id != noteId).toList(),
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return false;
  }

  Future<bool> permanentDeleteNote(String noteId) async {
    try {
      final response = await _api.dio.delete('/notes/$noteId/permanent');
      if (response.data['success'] == true) {
        state = state.copyWith(
          notes: state.notes.where((n) => n.id != noteId).toList(),
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return false;
  }
}

final trashProvider = StateNotifierProvider<TrashNotifier, TrashState>((ref) {
  return TrashNotifier();
});
