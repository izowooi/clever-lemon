import '../../models/poetry_template.dart';

abstract class PoetryService {
  /// 선택된 키워드들을 바탕으로 AI가 생성한 시 템플릿들을 가져옵니다.
  Future<List<PoetryTemplate>> generatePoetryTemplates(List<String> keywords);

  /// 특정 키워드들로 시를 생성합니다.
  Future<PoetryTemplate> generatePoetryFromKeywords(List<String> keywords);
}
