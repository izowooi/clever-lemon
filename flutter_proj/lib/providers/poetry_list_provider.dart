import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poetry.dart';
import '../services/implementations/drift_poetry_service.dart';
import 'database_provider.dart';

// 시 목록 상태 클래스
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

// 시 목록 StateNotifier
class PoetryListNotifier extends StateNotifier<PoetryListState> {
  final DriftPoetryService _poetryService;

  PoetryListNotifier(this._poetryService) : super(const PoetryListState()) {
    loadPoetries();
  }

  /// 모든 시를 로드합니다
  Future<void> loadPoetries() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final poetries = await _poetryService.getAllPoetries();
      // 최신순으로 정렬
      poetries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(poetries: poetries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '시 목록을 불러오는데 실패했습니다: $e',
      );
    }
  }

  /// 최근 시들만 로드합니다
  Future<void> loadRecentPoetries({int limit = 10}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final poetries = await _poetryService.getRecentPoetries(limit: limit);
      state = state.copyWith(poetries: poetries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '최근 시 목록을 불러오는데 실패했습니다: $e',
      );
    }
  }

  /// 시를 검색합니다
  Future<void> searchPoetries(String query) async {
    if (query.trim().isEmpty) {
      await loadPoetries();
      return;
    }

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final poetries = await _poetryService.searchPoetries(query);
      // 최신순으로 정렬
      poetries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(poetries: poetries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '시 검색에 실패했습니다: $e',
      );
    }
  }

  /// 시를 삭제합니다
  Future<void> deletePoetry(String id) async {
    try {
      await _poetryService.deletePoetry(id);
      // 목록에서 제거
      final updatedPoetries = state.poetries.where((p) => p.id != id).toList();
      state = state.copyWith(poetries: updatedPoetries);
    } catch (e) {
      state = state.copyWith(
        errorMessage: '시 삭제에 실패했습니다: $e',
      );
    }
  }

  /// 새로운 시가 추가되었을 때 목록을 새로고침합니다
  Future<void> refreshAfterSave() async {
    await loadPoetries();
  }

  /// 에러 메시지를 클리어합니다
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// StateNotifierProvider 정의
final poetryListProvider = StateNotifierProvider<PoetryListNotifier, PoetryListState>((ref) {
  final poetryService = ref.read(driftPoetryServiceProvider);
  return PoetryListNotifier(poetryService);
});