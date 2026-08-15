import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';

class FoldersState {
  final List<FolderModel> folders;
  final bool isLoading;
  final String? selectedFolderId;
  final String? error;

  FoldersState({
    this.folders = const [],
    this.isLoading = false,
    this.selectedFolderId,
    this.error,
  });

  FoldersState copyWith({
    List<FolderModel>? folders,
    bool? isLoading,
    String? selectedFolderId,
    String? error,
  }) {
    return FoldersState(
      folders: folders ?? this.folders,
      isLoading: isLoading ?? this.isLoading,
      selectedFolderId: selectedFolderId ?? this.selectedFolderId,
      error: error,
    );
  }
}

class FoldersNotifier extends StateNotifier<FoldersState> {
  final ApiClient _api = ApiClient();

  FoldersNotifier() : super(FoldersState()) {
    fetchFolders();
  }

  Future<void> fetchFolders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.get('/folders');
      if (response.data['success'] == true) {
        final rawList = response.data['data'] as List;
        final folders = rawList.map((e) => FolderModel.fromJson(e)).toList();
        state = state.copyWith(folders: folders, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load folders');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<FolderModel?> createFolder(String name, String workspaceId) async {
    try {
      final response = await _api.dio.post('/folders', data: {
        'name': name.trim(),
        'workspaceId': workspaceId,
      });
      if (response.data['success'] == true) {
        final newFolder = FolderModel.fromJson(response.data['data']);
        state = state.copyWith(folders: [...state.folders, newFolder]);
        return newFolder;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return null;
  }

  Future<bool> deleteFolder(String folderId) async {
    try {
      final response = await _api.dio.delete('/folders/$folderId');
      if (response.data['success'] == true) {
        state = state.copyWith(
          folders: state.folders.where((f) => f.id != folderId).toList(),
          selectedFolderId: state.selectedFolderId == folderId ? null : state.selectedFolderId,
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return false;
  }

  void selectFolder(String? folderId) {
    state = state.copyWith(selectedFolderId: folderId);
  }
}

final foldersProvider = StateNotifierProvider<FoldersNotifier, FoldersState>((ref) {
  return FoldersNotifier();
});
