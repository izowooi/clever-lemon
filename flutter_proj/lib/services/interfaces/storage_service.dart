import '../../models/daily_quote.dart';

abstract class StorageService {
  /// 글귀를 저장합니다.
  Future<void> saveDailyQuote(DailyQuote dailyQuote);

  /// 저장된 모든 글귀를 가져옵니다.
  Future<List<DailyQuote>> getAllDailyQuotes();

  /// 특정 ID의 글귀를 가져옵니다.
  Future<DailyQuote?> getDailyQuoteById(String id);

  /// 글귀를 삭제합니다.
  Future<void> deleteDailyQuote(String id);

  /// 글귀를 업데이트합니다.
  Future<void> updateDailyQuote(DailyQuote dailyQuote);
}
