import '../../models/daily_quote_template.dart';

abstract class DailyQuoteService {
  /// 선택된 키워드들을 바탕으로 AI가 생성한 오늘의 글귀 템플릿들을 가져옵니다.
  Future<List<DailyQuoteTemplate>> generateDailyQuoteTemplates(List<String> keywords);

  /// 특정 키워드들로 오늘의 글귀를 생성합니다.
  Future<DailyQuoteTemplate> generateDailyQuoteFromKeywords(List<String> keywords);
}
