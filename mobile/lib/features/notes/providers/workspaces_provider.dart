import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';

class WorkspacesState {
  final List<WorkspaceModel> workspaces;
  final bool isLoading;
  final String? selectedWorkspaceId;
  final String? error;

  WorkspacesState({
    this.workspaces = const [],
    this.isLoading = false,
    this.selectedWorkspaceId,
    this.error,
  });

  WorkspacesState copyWith({
    List<WorkspaceModel>? workspaces,
    bool? isLoading,
    String? selectedWorkspaceId,
    String? error,
  }) {
    return WorkspacesState(
      workspaces: workspaces ?? this.workspaces,
      isLoading: isLoading ?? this.isLoading,
      selectedWorkspaceId: selectedWorkspaceId ?? this.selectedWorkspaceId,
      error: error,
    );
  }
}

class WorkspacesNotifier extends StateNotifier<WorkspacesState> {
  final ApiClient _api = ApiClient();

  WorkspacesNotifier() : super(WorkspacesState()) {
    fetchWorkspaces();
  }

  Future<void> fetchWorkspaces() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.get('/workspaces');
      if (response.data['success'] == true) {
        final rawList = response.data['data'] as List;
        final workspaces = rawList.map((e) => WorkspaceModel.fromJson(e)).toList();
        state = state.copyWith(workspaces: workspaces, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load workspaces');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<WorkspaceModel?> createWorkspace(String name, {String? icon}) async {
    try {
      final response = await _api.dio.post('/workspaces', data: {
        'name': name.trim(),
        'icon': icon,
      });
      if (response.data['success'] == true) {
        final newWs = WorkspaceModel.fromJson(response.data['data']);
        state = state.copyWith(workspaces: [...state.workspaces, newWs]);
        return newWs;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return null;
  }

  Future<bool> deleteWorkspace(String workspaceId) async {
    try {
      final response = await _api.dio.delete('/workspaces/$workspaceId');
      if (response.data['success'] == true) {
        state = state.copyWith(
          workspaces: state.workspaces.where((w) => w.id != workspaceId).toList(),
          selectedWorkspaceId:
              state.selectedWorkspaceId == workspaceId ? null : state.selectedWorkspaceId,
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return false;
  }

  void selectWorkspace(String? workspaceId) {
    state = state.copyWith(selectedWorkspaceId: workspaceId);
  }
}

final workspacesProvider = StateNotifierProvider<WorkspacesNotifier, WorkspacesState>((ref) {
  return WorkspacesNotifier();
});
