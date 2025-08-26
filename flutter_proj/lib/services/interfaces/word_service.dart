import '../../models/word.dart';

abstract class WordService {
  /// 무작위로 5개의 단어를 가져옵니다.
  Future<List<Word>> getRandomWords({int count = 5});

  /// 특정 카테고리의 무작위 단어들을 가져옵니다.
  Future<List<Word>> getRandomWordsByCategory(String category, {int count = 5});

  /// 모든 카테고리를 가져옵니다.
  Future<List<String>> getAllCategories();
}
