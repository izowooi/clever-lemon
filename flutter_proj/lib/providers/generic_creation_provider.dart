import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word.dart';
import '../models/poetry.dart';
import '../models/poetry_template.dart';
import '../services/interfaces/word_service.dart';
import '../services/interfaces/poem_api_service.dart';
import '../services/implementations/mock_word_service.dart';
import '../services/implementations/http_poem_api_service.dart';
import '../main.dart';
import 'database_provider.dart';
import 'poetry_list_provider.dart';
import 'user_credits_provider.dart';

enum CreationStep {
  styleSelection,
  authorStyleSelection,
  lengthSelection,
  wordSelection,
  templateSelection,
}

enum CreationType {
  poetry,
  dailyVerse,
}

// 상태 클래스
class GenericCreationState {
  final CreationStep currentStep;
  final int sequentialStep;
  final List<Word> currentWords;
  final List<Word> selectedWords;
  final List<PoetryTemplate> generatedTemplates;
  final bool isLoading;
  final String? errorMessage;
  final CreationType creationType;

  // 설정 관련 필드들
  final String? selectedStyle;
  final String? selectedAuthorStyle;
  final int? selectedLength;

  const GenericCreationState({
    this.currentStep = CreationStep.styleSelection,
    this.sequentialStep = 0,
    this.currentWords = const [],
    this.selectedWords = const [],
    this.generatedTemplates = const [],
    this.isLoading = false,
    this.errorMessage,
    required this.creationType,
    this.selectedStyle,
    this.selectedAuthorStyle,
    this.selectedLength,
  });

  GenericCreationState copyWith({
    CreationStep? currentStep,
    int? sequentialStep,
    List<Word>? currentWords,
    List<Word>? selectedWords,
    List<PoetryTemplate>? generatedTemplates,
    bool? isLoading,
    String? errorMessage,
    CreationType? creationType,
    String? selectedStyle,
    String? selectedAuthorStyle,
    int? selectedLength,
  }) {
    return GenericCreationState(
      currentStep: currentStep ?? this.currentStep,
      sequentialStep: sequentialStep ?? this.sequentialStep,
      currentWords: currentWords ?? this.currentWords,
      selectedWords: selectedWords ?? this.selectedWords,
      generatedTemplates: generatedTemplates ?? this.generatedTemplates,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      creationType: creationType ?? this.creationType,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      selectedAuthorStyle: selectedAuthorStyle ?? this.selectedAuthorStyle,
      selectedLength: selectedLength ?? this.selectedLength,
    );
  }
}

// StateNotifier 클래스
class GenericCreationNotifier extends StateNotifier<GenericCreationState> {
  final WordService _wordService;
  final PoemApiService _poemApiService;
  final Ref _ref;
  final CreationType _creationType;

  GenericCreationNotifier({
    required WordService wordService,
    required PoemApiService poemApiService,
    required Ref ref,
    required CreationType creationType,
  })  : _wordService = wordService,
        _poemApiService = poemApiService,
        _ref = ref,
        _creationType = creationType,
        super(GenericCreationState(creationType: creationType)) {
    startNewCreation();
  }

  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void _setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  /// 새로운 창작 과정을 시작합니다
  Future<void> startNewCreation() async {
    state = GenericCreationState(creationType: _creationType);
  }

  /// 무작위 단어들을 로드합니다
  Future<void> loadRandomWords() async {
    try {
      _setLoading(true);
      final words = await _wordService.getRandomWords();
      state = state.copyWith(currentWords: words, isLoading: false);
    } catch (e) {
      _setError('단어를 불러오는데 실패했습니다: $e');
      _setLoading(false);
    }
  }

  /// 스타일을 선택합니다
  void selectStyle(String style) {
    state = state.copyWith(
      selectedStyle: style,
      currentStep: CreationStep.authorStyleSelection,
    );
  }

  /// 작가 스타일을 선택합니다
  void selectAuthorStyle(String authorStyle) {
    state = state.copyWith(
      selectedAuthorStyle: authorStyle,
      currentStep: CreationStep.lengthSelection,
    );
  }

  /// 길이를 선택합니다
  void selectLength(int length) {
    state = state.copyWith(
      selectedLength: length,
      currentStep: CreationStep.wordSelection,
    );
    // 단어 선택 단계로 넘어가면서 첫 번째 단어를 로드
    loadRandomWords();
  }

  /// 단어를 선택합니다 (순차적 선택)
  void selectWordSequentially(Word word) {
    if (state.selectedWords.length < 3) {
      final newSelectedWords = [...state.selectedWords, word];
      final newStep = state.sequentialStep + 1;

      state = state.copyWith(
        selectedWords: newSelectedWords,
        sequentialStep: newStep,
      );

      if (newSelectedWords.length == 3) {
        _generateTemplates();
      } else {
        loadRandomWords(); // 다음 단계를 위한 새로운 단어들 로드
      }
    }
  }

  /// 템플릿을 생성합니다 (실제 API 호출)
  Future<void> _generateTemplates() async {
    try {
      _setLoading(true);
      final keywords = state.selectedWords.map((w) => w.text).toList();

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        _setError('로그인이 필요합니다.');
        _setLoading(false);
        return;
      }

      final request = PoemGenerateRequest(
        userId: currentUser.id,
        style: state.selectedStyle ?? 'default',
        authorStyle: state.selectedAuthorStyle ?? 'default',
        keywords: keywords,
        length: "${state.selectedLength ?? 12}행",
      );

      // CreationType에 따라 적절한 API 메소드 호출
      final result = _creationType == CreationType.poetry
          ? await _poemApiService.generatePoem(request)
          : await _poemApiService.generateDailyVerse(request);

      if (result.isSuccess && result.data != null) {
        // CreationType에 따라 적절한 파싱 메소드 호출
        final templates = _creationType == CreationType.poetry
            ? _convertPoemResponseToTemplates(result.data!, keywords)
            : _convertDailyVerseResponseToTemplates(result.data!, keywords);

        // 모든 결과물을 바로 저장
        await _saveAllResults(templates, keywords);

        state = state.copyWith(
          currentStep: CreationStep.templateSelection,
          generatedTemplates: templates,
          isLoading: false,
        );
      } else {
        final errorMsg = _creationType == CreationType.poetry
            ? '시 생성에 실패했습니다: ${result.message}'
            : '글귀 생성에 실패했습니다: ${result.message}';
        _setError(errorMsg);
        _setLoading(false);
      }
    } catch (e) {
      final errorMsg = _creationType == CreationType.poetry
          ? '시 생성 API 호출 오류: $e'
          : '글귀 생성 API 호출 오류: $e';
      _setError(errorMsg);
      _setLoading(false);
    }
  }

  /// 모든 결과물을 데이터베이스에 저장합니다
  Future<void> _saveAllResults(List<PoetryTemplate> templates, List<String> keywords) async {
    try {
      final poetryService = _ref.read(driftPoetryServiceProvider);

      for (final template in templates) {
        final poetry = Poetry(
          id: '${DateTime.now().millisecondsSinceEpoch}_${templates.indexOf(template)}',
          title: template.title,
          content: template.content,
          keywords: keywords,
          createdAt: DateTime.now(),
          isFromTemplate: true,
          templateId: template.id,
        );

        await poetryService.savePoetry(poetry);
      }

      // 목록 새로고침
      _ref.read(poetryListProvider.notifier).refreshAfterSave();

      // 재화 정보 새로고침
      _ref.read(userCreditsProvider.notifier).refreshCredits();
    } catch (e) {
      // 저장 실패해도 UI는 계속 진행
      // ignore: avoid_print
      print('결과물 저장 중 오류 발생: $e');
    }
  }

  /// 시 생성 API 응답을 PoetryTemplate 리스트로 변환합니다
  List<PoetryTemplate> _convertPoemResponseToTemplates(Map<String, dynamic> apiData, List<String> keywords) {
    final templates = <PoetryTemplate>[];

    if (apiData['poems'] is List) {
      final poems = apiData['poems'] as List;
      for (int i = 0; i < poems.length; i++) {
        final poem = poems[i];
        if (poem is String) {
          final parsedPoem = _parsePoemString(poem);
          final template = PoetryTemplate(
            id: 'api_${DateTime.now().millisecondsSinceEpoch}_$i',
            title: parsedPoem['title'] ?? '시 ${i + 1}',
            content: parsedPoem['content'] ?? poem,
            keywords: keywords,
            createdAt: DateTime.now(),
          );
          templates.add(template);
        } else if (poem is Map<String, dynamic>) {
          final template = PoetryTemplate(
            id: 'api_${DateTime.now().millisecondsSinceEpoch}_$i',
            title: poem['title'] ?? '제목 없음',
            content: poem['content'] ?? poem['text'] ?? '',
            keywords: keywords,
            createdAt: DateTime.now(),
          );
          templates.add(template);
        }
      }
    }

    if (templates.isEmpty) {
      templates.add(PoetryTemplate(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        title: '생성된 시',
        content: apiData['content']?.toString() ?? apiData.toString(),
        keywords: keywords,
        createdAt: DateTime.now(),
      ));
    }

    return templates;
  }

  /// 오늘의 글귀 API 응답을 PoetryTemplate 리스트로 변환합니다
  List<PoetryTemplate> _convertDailyVerseResponseToTemplates(Map<String, dynamic> apiData, List<String> keywords) {
    final templates = <PoetryTemplate>[];

    if (apiData['quotes'] is List) {
      final quotes = apiData['quotes'] as List;
      for (int i = 0; i < quotes.length; i++) {
        final verse = quotes[i];
        if (verse is String) {
          final template = PoetryTemplate(
            id: 'api_${DateTime.now().millisecondsSinceEpoch}_$i',
            title: '글귀 ${i + 1}',
            content: verse,
            keywords: keywords,
            createdAt: DateTime.now(),
          );
          templates.add(template);
        } else if (verse is Map<String, dynamic>) {
          final template = PoetryTemplate(
            id: 'api_${DateTime.now().millisecondsSinceEpoch}_$i',
            title: verse['title'] ?? '글귀 ${i + 1}',
            content: verse['content'] ?? verse['text'] ?? '',
            keywords: keywords,
            createdAt: DateTime.now(),
          );
          templates.add(template);
        }
      }
    }

    if (templates.isEmpty) {
      templates.add(PoetryTemplate(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        title: '생성된 글귀',
        content: apiData['content']?.toString() ?? apiData.toString(),
        keywords: keywords,
        createdAt: DateTime.now(),
      ));
    }

    return templates;
  }

  /// 문자열 형태의 결과물을 파싱하여 제목과 내용을 분리합니다
  Map<String, String> _parsePoemString(String poemString) {
    String title = '제목 없음';
    String content = poemString;

    // '\n\n'으로 제목과 내용을 분리
    final doubleLfIndex = poemString.indexOf('\n\n');
    if (doubleLfIndex != -1) {
      title = poemString.substring(0, doubleLfIndex).trim();
      content = poemString.substring(doubleLfIndex + 2).trim();
    } else {
      // '\n\n'이 없는 경우 첫 번째 줄을 제목으로 처리
      final lines = poemString.split('\n');
      if (lines.isNotEmpty) {
        title = lines[0].trim();
        if (lines.length > 1) {
          content = lines.skip(1).join('\n').trim();
        }
      }
    }

    return {
      'title': title,
      'content': content,
    };
  }

  /// 에러를 클리어합니다
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 이전 단계로 돌아갑니다
  void goToPreviousStep() {
    switch (state.currentStep) {
      case CreationStep.authorStyleSelection:
        state = state.copyWith(
          selectedAuthorStyle: null,
          currentStep: CreationStep.styleSelection,
        );
        break;
      case CreationStep.lengthSelection:
        state = state.copyWith(
          selectedLength: null,
          currentStep: CreationStep.authorStyleSelection,
        );
        break;
      case CreationStep.wordSelection:
        if (state.selectedWords.isEmpty) {
          state = state.copyWith(
            currentStep: CreationStep.lengthSelection,
            currentWords: [],
            sequentialStep: 0,
          );
        } else {
          final newSelectedWords = [...state.selectedWords];
          newSelectedWords.removeLast();
          final newStep = state.sequentialStep - 1;

          state = state.copyWith(
            selectedWords: newSelectedWords,
            sequentialStep: newStep,
          );

          loadRandomWords();
        }
        break;
      case CreationStep.templateSelection:
        if (state.selectedWords.isNotEmpty) {
          final newSelectedWords = [...state.selectedWords];
          newSelectedWords.removeLast();

          state = state.copyWith(
            selectedWords: newSelectedWords,
            currentStep: CreationStep.wordSelection,
            generatedTemplates: [],
            sequentialStep: state.selectedWords.length - 1,
          );

          loadRandomWords();
        }
        break;
      case CreationStep.styleSelection:
        // 첫 번째 단계이므로 뒤로갈 수 없음
        break;
    }
  }

  /// 현재 단계에서 뒤로갈 수 있는지 확인
  bool canGoBack() {
    switch (state.currentStep) {
      case CreationStep.styleSelection:
        return false;
      case CreationStep.authorStyleSelection:
      case CreationStep.lengthSelection:
        return true;
      case CreationStep.wordSelection:
        return true;
      case CreationStep.templateSelection:
        return true;
    }
  }
}

// 서비스 프로바이더들
final wordServiceProvider = Provider<WordService>((ref) {
  return MockWordService();
});

final poemApiServiceProvider = Provider<PoemApiService>((ref) => HttpPoemApiService());

// 시 창작용 Provider
final poetryCreationProvider = StateNotifierProvider<GenericCreationNotifier, GenericCreationState>((ref) {
  final wordService = ref.read(wordServiceProvider);
  final poemApiService = ref.read(poemApiServiceProvider);

  return GenericCreationNotifier(
    wordService: wordService,
    poemApiService: poemApiService,
    ref: ref,
    creationType: CreationType.poetry,
  );
});

// 오늘의 글귀용 Provider
final dailyVerseCreationProvider = StateNotifierProvider<GenericCreationNotifier, GenericCreationState>((ref) {
  final wordService = ref.read(wordServiceProvider);
  final poemApiService = ref.read(poemApiServiceProvider);

  return GenericCreationNotifier(
    wordService: wordService,
    poemApiService: poemApiService,
    ref: ref,
    creationType: CreationType.dailyVerse,
  );
});