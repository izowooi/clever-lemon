import 'dart:math';
import '../interfaces/word_service.dart';
import '../../models/word.dart';
import '../remote_config_service.dart';

class MockWordService implements WordService {
  static const List<Word> _fallbackWords = [
    // 자연 카테고리
    Word(id: '1', text: '바람', category: '자연'),
    Word(id: '2', text: '구름', category: '자연'),
    Word(id: '3', text: '꽃', category: '자연'),
    Word(id: '4', text: '바다', category: '자연'),
    Word(id: '5', text: '달', category: '자연'),
    Word(id: '6', text: '별', category: '자연'),
    Word(id: '7', text: '나무', category: '자연'),
    Word(id: '8', text: '강', category: '자연'),
    Word(id: '9', text: '산', category: '자연'),
    Word(id: '10', text: '햇살', category: '자연'),

    // 감정 카테고리
    Word(id: '11', text: '그리움', category: '감정'),
    Word(id: '12', text: '사랑', category: '감정'),
    Word(id: '13', text: '기쁨', category: '감정'),
    Word(id: '14', text: '슬픔', category: '감정'),
    Word(id: '15', text: '희망', category: '감정'),
    Word(id: '16', text: '외로움', category: '감정'),
    Word(id: '17', text: '위로', category: '감정'),
    Word(id: '18', text: '평화', category: '감정'),
    Word(id: '19', text: '설렘', category: '감정'),
    Word(id: '20', text: '추억', category: '감정'),

    // 시간 카테고리
    Word(id: '21', text: '어린 시절', category: '시간'),
    Word(id: '22', text: '봄날', category: '시간'),
    Word(id: '23', text: '가을밤', category: '시간'),
    Word(id: '24', text: '새벽', category: '시간'),
    Word(id: '25', text: '황혼', category: '시간'),
    Word(id: '26', text: '순간', category: '시간'),
    Word(id: '27', text: '영원', category: '시간'),
    Word(id: '28', text: '여름날', category: '시간'),
    Word(id: '29', text: '겨울밤', category: '시간'),
    Word(id: '30', text: '현재', category: '시간'),
  ];

  final Random _random = Random();
  List<Word>? _wordsCache;

  Future<List<Word>> _getWords() async {
    if (_wordsCache != null) {
      return _wordsCache!;
    }

    try {
      final remoteConfig = RemoteConfigService.instance;
      final poemWorlds = remoteConfig.getPoemWorlds();

      if (poemWorlds != null) {
        final List<Word> words = [];
        int idCounter = 1;

        poemWorlds.forEach((category, wordsList) {
          if (wordsList is List) {
            for (final wordText in wordsList) {
              if (wordText is String) {
                words.add(Word(
                  id: idCounter.toString(),
                  text: wordText,
                  category: category,
                ));
                idCounter++;
              }
            }
          }
        });

        if (words.isNotEmpty) {
          _wordsCache = words;
          return words;
        }
      }
    } catch (e) {
      print('Remote Config에서 단어를 가져오는데 실패했습니다: $e');
    }

    // fallback으로 기본 단어 사용
    _wordsCache = List<Word>.from(_fallbackWords);
    return _wordsCache!;
  }

  @override
  Future<List<Word>> getRandomWords({int count = 5}) async {
    // 실제 서버 통신을 시뮬레이션하기 위한 지연
    await Future.delayed(const Duration(milliseconds: 300));

    final words = await _getWords();
    final shuffled = List<Word>.from(words)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  @override
  Future<List<Word>> getRandomWordsByCategory(String category, {int count = 5}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final words = await _getWords();
    final wordsInCategory = words.where((word) => word.category == category).toList();
    wordsInCategory.shuffle(_random);
    return wordsInCategory.take(count).toList();
  }

  @override
  Future<List<String>> getAllCategories() async {
    await Future.delayed(const Duration(milliseconds: 100));

    final words = await _getWords();
    return words.map((word) => word.category).toSet().toList();
  }
}
