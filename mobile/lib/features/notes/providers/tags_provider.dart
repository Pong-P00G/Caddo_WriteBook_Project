import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';

class TagsState {
  final List<TagModel> tags;
  final bool isLoading;
  final String? selectedTagId;
  final String? error;

  TagsState({
    this.tags = const [],
    this.isLoading = false,
    this.selectedTagId,
    this.error,
  });

  TagsState copyWith({
    List<TagModel>? tags,
    bool? isLoading,
    String? selectedTagId,
    String? error,
  }) {
    return TagsState(
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      selectedTagId: selectedTagId ?? this.selectedTagId,
      error: error,
    );
  }
}

class TagsNotifier extends StateNotifier<TagsState> {
  final ApiClient _api = ApiClient();

  TagsNotifier() : super(TagsState()) {
    fetchTags();
  }

  Future<void> fetchTags() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.get('/tags');
      if (response.data['success'] == true) {
        final rawList = response.data['data'] as List;
        final tags = rawList.map((e) => TagModel.fromJson(e)).toList();
        state = state.copyWith(tags: tags, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load tags');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<TagModel?> createTag(String name, String color) async {
    try {
      final response = await _api.dio.post('/tags', data: {
        'name': name.trim().toLowerCase(),
        'color': color,
      });
      if (response.data['success'] == true) {
        final newTag = TagModel.fromJson(response.data['data']);
        state = state.copyWith(tags: [...state.tags, newTag]);
        return newTag;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return null;
  }

  Future<void> deleteTag(String id) async {
    try {
      final response = await _api.dio.delete('/tags/$id');
      if (response.data['success'] == true) {
        final updatedList = state.tags.where((t) => t.id != id).toList();
        state = state.copyWith(tags: updatedList);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void selectTag(String? tagId) {
    state = state.copyWith(selectedTagId: tagId);
  }
}

final tagsProvider = StateNotifierProvider<TagsNotifier, TagsState>((ref) {
  return TagsNotifier();
});
