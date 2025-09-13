import 'dart:math';
import '../interfaces/daily_quote_service.dart';
import '../../models/daily_quote_template.dart';

class MockDailyQuoteService implements DailyQuoteService {
  final Random _random = Random();

  static const List<String> _templateFormats = [
    '''%s이 흘러가고
%s 속에서
%s을 찾는다

시간은 멈춰있고
내 마음만
천천히 흘러간다''',

    '''한 송이 %s처럼
%s을 품고
%s 향해 걸어간다

끝없는 여행 속에서
작은 희망 하나
가슴에 품고서''',

    '''%s의 노래가
귓가에 울려퍼진다
%s같은 그대와
%s을 나누며

우리가 걸어온 길
돌이켜보니
모든 것이 소중했다''',

    '''저 멀리 %s이 보이고
%s을 타고 오는
%s의 메시지

오늘도 새로운 하루가
우리를 기다리고 있다
희망과 함께''',
  ];

  @override
  Future<List<DailyQuoteTemplate>> generateDailyQuoteTemplates(List<String> keywords) async {
    // AI 서버 통신 시뮬레이션
    await Future.delayed(const Duration(seconds: 2));

    final templates = <DailyQuoteTemplate>[];

    for (int i = 0; i < 4; i++) {
      final format = _templateFormats[_random.nextInt(_templateFormats.length)];
      final shuffledKeywords = List<String>.from(keywords)..shuffle(_random);

      // 키워드를 템플릿에 삽입
      String content = format;
      for (int j = 0; j < shuffledKeywords.length && j < 3; j++) {
        content = content.replaceFirst('%s', shuffledKeywords[j]);
      }

      templates.add(DailyQuoteTemplate(
        id: 'template_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: '${shuffledKeywords.first}에 대한 글귀',
        content: content,
        keywords: keywords,
        createdAt: DateTime.now(),
      ));
    }

    return templates;
  }

  @override
  Future<DailyQuoteTemplate> generateDailyQuoteFromKeywords(List<String> keywords) async {
    final templates = await generateDailyQuoteTemplates(keywords);
    return templates.first;
  }
}
