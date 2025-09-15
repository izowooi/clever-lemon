import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word.dart';
import '../models/poetry.dart';
import '../models/poetry_template.dart';
import '../services/interfaces/word_service.dart';
import '../services/interfaces/poetry_service.dart';
import '../services/interfaces/storage_service.dart';
import '../services/interfaces/poem_api_service.dart';
import '../services/implementations/mock_word_service.dart';
import '../services/implementations/mock_poetry_service.dart';
import '../services/implementations/local_storage_service.dart';
import '../services/implementations/http_poem_api_service.dart';
import '../main.dart';
import 'poem_settings_provider.dart';

enum CreationStep {
  wordSelection,
  templateSelection,
  editing,
  completed,
}

// 서비스 프로바이더들
final wordServiceProvider = Provider<WordService>((ref) => MockWordService());
final poetryServiceProvider = Provider<PoetryService>((ref) => MockPoetryService());
final storageServiceProvider = Provider<StorageService>((ref) => LocalStorageService());
final poemApiServiceProvider = Provider<PoemApiService>((ref) => HttpPoemApiService());

// 상태 클래스
class PoetryCreationState {
  final CreationStep currentStep;
  final int sequentialStep;
  final List<Word> currentWords;
  final List<Word> selectedWords;
  final List<PoetryTemplate> generatedTemplates;
  final PoetryTemplate? selectedTemplate;
  final Poetry? editingPoetry;
  final bool isLoading;
  final String? errorMessage;

  const PoetryCreationState({
    this.currentStep = CreationStep.wordSelection,
    this.sequentialStep = 0,
    this.currentWords = const [],
    this.selectedWords = const [],
    this.generatedTemplates = const [],
    this.selectedTemplate,
    this.editingPoetry,
    this.isLoading = false,
    this.errorMessage,
  });

  PoetryCreationState copyWith({
    CreationStep? currentStep,
    int? sequentialStep,
    List<Word>? currentWords,
    List<Word>? selectedWords,
    List<PoetryTemplate>? generatedTemplates,
    PoetryTemplate? selectedTemplate,
    Poetry? editingPoetry,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PoetryCreationState(
      currentStep: currentStep ?? this.currentStep,
      sequentialStep: sequentialStep ?? this.sequentialStep,
      currentWords: currentWords ?? this.currentWords,
      selectedWords: selectedWords ?? this.selectedWords,
      generatedTemplates: generatedTemplates ?? this.generatedTemplates,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      editingPoetry: editingPoetry ?? this.editingPoetry,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// StateNotifier 클래스
class PoetryCreationNotifier extends StateNotifier<PoetryCreationState> {
  final WordService _wordService;
  final PoetryService _poetryService;
  final StorageService _storageService;
  final PoemApiService _poemApiService;
  final Ref _ref;

  PoetryCreationNotifier({
    required WordService wordService,
    required PoetryService poetryService,
    required StorageService storageService,
    required PoemApiService poemApiService,
    required Ref ref,
  })  : _wordService = wordService,
        _poetryService = poetryService,
        _storageService = storageService,
        _poemApiService = poemApiService,
        _ref = ref,
        super(const PoetryCreationState()) {
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
    state = const PoetryCreationState();
    await loadRandomWords();
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

  /// 시를 생성합니다 (실제 API 호출)
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
      
      final poemSettings = _ref.read(poemSettingsProvider);

      final request = PoemGenerateRequest(
        userId: currentUser.id,
        style: poemSettings.style,
        authorStyle: poemSettings.authorStyle,
        keywords: keywords,
        length: poemSettings.length.toString() + "행",
      );
      
      final result = await _poemApiService.generatePoem(request);
      
      if (result.isSuccess && result.data != null) {
        final templates = _convertApiResponseToTemplates(result.data!, keywords);
        state = state.copyWith(
          currentStep: CreationStep.templateSelection,
          generatedTemplates: templates,
          isLoading: false,
        );
      } else {
        _setError('시 생성에 실패했습니다: ${result.message}');
        _setLoading(false);
      }
    } catch (e) {
      _setError('시 생성 API 호출 오류: $e');
      _setLoading(false);
    }
  }

  /// API 응답을 PoetryTemplate 리스트로 변환합니다
  List<PoetryTemplate> _convertApiResponseToTemplates(Map<String, dynamic> apiData, List<String> keywords) {
    final templates = <PoetryTemplate>[];
    
    if (apiData['poems'] is List) {
      final poems = apiData['poems'] as List;
      for (int i = 0; i < poems.length; i++) {
        final poem = poems[i];
        if (poem is String) {
          // 문자열에서 제목과 내용을 파싱
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

  /// 문자열 형태의 시를 파싱하여 제목과 내용을 분리합니다
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

  /// 템플릿을 선택하고 편집 단계로 이동합니다
  void selectTemplate(PoetryTemplate template) {
    // 편집용 Poetry 객체 생성
    final editingPoetry = Poetry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: template.title,
      content: template.content,
      keywords: template.keywords,
      createdAt: DateTime.now(),
      isFromTemplate: true,
      templateId: template.id,
    );
    
    state = state.copyWith(
      selectedTemplate: template,
      currentStep: CreationStep.editing,
      editingPoetry: editingPoetry,
    );
  }

  /// 시의 내용을 업데이트합니다
  void updatePoetryContent(String title, String content) {
    if (state.editingPoetry != null) {
      final updatedPoetry = state.editingPoetry!.copyWith(
        title: title,
        content: content,
        modifiedAt: DateTime.now(),
      );
      state = state.copyWith(editingPoetry: updatedPoetry);
    }
  }

  /// 시를 저장합니다
  Future<void> savePoetry() async {
    if (state.editingPoetry == null) return;
    
    try {
      _setLoading(true);
      await _storageService.savePoetry(state.editingPoetry!);
      state = state.copyWith(
        currentStep: CreationStep.completed,
        isLoading: false,
      );
    } catch (e) {
      _setError('시 저장에 실패했습니다: $e');
      _setLoading(false);
    }
  }

  /// 에러를 클리어합니다
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// StateNotifierProvider 정의
final poetryCreationProvider = StateNotifierProvider<PoetryCreationNotifier, PoetryCreationState>((ref) {
  final wordService = ref.read(wordServiceProvider);
  final poetryService = ref.read(poetryServiceProvider);
  final storageService = ref.read(storageServiceProvider);
  final poemApiService = ref.read(poemApiServiceProvider);

  return PoetryCreationNotifier(
    wordService: wordService,
    poetryService: poetryService,
    storageService: storageService,
    poemApiService: poemApiService,
    ref: ref,
  );
});
