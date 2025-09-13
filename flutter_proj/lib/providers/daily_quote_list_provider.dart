import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_quote.dart';
import '../services/interfaces/storage_service.dart';
import 'daily_quote_creation_provider.dart'; // storageServiceProvider를 위해 import

// 상태 클래스
class DailyQuoteListState {
  final List<DailyQuote> dailyQuotes;
  final bool isLoading;
  final String? errorMessage;

  const DailyQuoteListState({
    this.dailyQuotes = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DailyQuoteListState copyWith({
    List<DailyQuote>? dailyQuotes,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DailyQuoteListState(
      dailyQuotes: dailyQuotes ?? this.dailyQuotes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// StateNotifier 클래스
class DailyQuoteListNotifier extends StateNotifier<DailyQuoteListState> {
  final StorageService _storageService;

  DailyQuoteListNotifier({required StorageService storageService})
      : _storageService = storageService,
        super(const DailyQuoteListState());

  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void _setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  /// 저장된 모든 글귀를 로드합니다
  Future<void> loadDailyQuotes() async {
    try {
      _setLoading(true);
      final dailyQuotes = await _storageService.getAllDailyQuotes();
      // 최신순으로 정렬
      dailyQuotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(dailyQuotes: dailyQuotes, isLoading: false);
    } catch (e) {
      _setError('글귀 목록을 불러오는데 실패했습니다: $e');
      _setLoading(false);
    }
  }

  /// 글귀를 삭제합니다
  Future<void> deleteDailyQuote(String id) async {
    try {
      _setLoading(true);
      await _storageService.deleteDailyQuote(id);
      final updatedDailyQuotes = state.dailyQuotes.where((dailyQuote) => dailyQuote.id != id).toList();
      state = state.copyWith(dailyQuotes: updatedDailyQuotes, isLoading: false);
    } catch (e) {
      _setError('글귀 삭제에 실패했습니다: $e');
      _setLoading(false);
    }
  }

  /// 글귀를 업데이트합니다
  Future<void> updateDailyQuote(DailyQuote updatedDailyQuote) async {
    try {
      _setLoading(true);
      await _storageService.updateDailyQuote(updatedDailyQuote);

      final dailyQuotes = List<DailyQuote>.from(state.dailyQuotes);
      final index = dailyQuotes.indexWhere((dq) => dq.id == updatedDailyQuote.id);
      if (index != -1) {
        dailyQuotes[index] = updatedDailyQuote;
        // 수정시간 기준으로 재정렬
        dailyQuotes.sort((a, b) {
          final aTime = a.modifiedAt ?? a.createdAt;
          final bTime = b.modifiedAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
      }

      state = state.copyWith(dailyQuotes: dailyQuotes, isLoading: false);
    } catch (e) {
      _setError('글귀 업데이트에 실패했습니다: $e');
      _setLoading(false);
    }
  }

  /// 에러를 클리어합니다
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// StateNotifierProvider 정의
final dailyQuoteListProvider = StateNotifierProvider<DailyQuoteListNotifier, DailyQuoteListState>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return DailyQuoteListNotifier(storageService: storageService);
});
