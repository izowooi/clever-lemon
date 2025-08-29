import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poetry.dart';
import '../services/interfaces/storage_service.dart';
import 'poetry_creation_provider.dart'; // storageServiceProvider를 위해 import

// 상태 클래스
class PoetryListState {
  final List<Poetry> poetries;
  final bool isLoading;
  final String? errorMessage;

  const PoetryListState({
    this.poetries = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PoetryListState copyWith({
    List<Poetry>? poetries,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PoetryListState(
      poetries: poetries ?? this.poetries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// StateNotifier 클래스
class PoetryListNotifier extends StateNotifier<PoetryListState> {
  final StorageService _storageService;

  PoetryListNotifier({required StorageService storageService})
      : _storageService = storageService,
        super(const PoetryListState());

  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void _setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  /// 저장된 모든 시를 로드합니다
  Future<void> loadPoetries() async {
    try {
      _setLoading(true);
      final poetries = await _storageService.getAllPoetries();
      // 최신순으로 정렬
      poetries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(poetries: poetries, isLoading: false);
    } catch (e) {
      _setError('시 목록을 불러오는데 실패했습니다: $e');
      _setLoading(false);
    }
  }

  /// 시를 삭제합니다
  Future<void> deletePoetry(String id) async {
    try {
      _setLoading(true);
      await _storageService.deletePoetry(id);
      final updatedPoetries = state.poetries.where((poetry) => poetry.id != id).toList();
      state = state.copyWith(poetries: updatedPoetries, isLoading: false);
    } catch (e) {
      _setError('시 삭제에 실패했습니다: $e');
      _setLoading(false);
    }
  }

  /// 시를 업데이트합니다
  Future<void> updatePoetry(Poetry updatedPoetry) async {
    try {
      _setLoading(true);
      await _storageService.updatePoetry(updatedPoetry);
      
      final poetries = List<Poetry>.from(state.poetries);
      final index = poetries.indexWhere((p) => p.id == updatedPoetry.id);
      if (index != -1) {
        poetries[index] = updatedPoetry;
        // 수정시간 기준으로 재정렬
        poetries.sort((a, b) {
          final aTime = a.modifiedAt ?? a.createdAt;
          final bTime = b.modifiedAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
      }
      
      state = state.copyWith(poetries: poetries, isLoading: false);
    } catch (e) {
      _setError('시 업데이트에 실패했습니다: $e');
      _setLoading(false);
    }
  }

  /// 에러를 클리어합니다
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// StateNotifierProvider 정의
final poetryListProvider = StateNotifierProvider<PoetryListNotifier, PoetryListState>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return PoetryListNotifier(storageService: storageService);
});
