import 'package:flutter/foundation.dart';
import '../models/word.dart';
import '../models/poetry.dart';
import '../models/poetry_template.dart';
import '../services/interfaces/word_service.dart';
import '../services/interfaces/poetry_service.dart';
import '../services/interfaces/storage_service.dart';

enum CreationStep {
  wordSelection,
  templateSelection,
  editing,
  completed,
}

class PoetryCreationProvider with ChangeNotifier {
  final WordService _wordService;
  final PoetryService _poetryService;
  final StorageService _storageService;

  PoetryCreationProvider({
    required WordService wordService,
    required PoetryService poetryService,
    required StorageService storageService,
  })  : _wordService = wordService,
        _poetryService = poetryService,
        _storageService = storageService;

  // 현재 단계
  CreationStep _currentStep = CreationStep.wordSelection;
  CreationStep get currentStep => _currentStep;

  // 현재 단계 (순차적 선택용)
  int _sequentialStep = 0;
  int get sequentialStep => _sequentialStep;

  // 무작위 단어들
  List<Word> _currentWords = [];
  List<Word> get currentWords => _currentWords;

  // 선택된 단어들
  List<Word> _selectedWords = [];
  List<Word> get selectedWords => _selectedWords;

  // 생성된 템플릿들
  List<PoetryTemplate> _generatedTemplates = [];
  List<PoetryTemplate> get generatedTemplates => _generatedTemplates;

  // 선택된 템플릿
  PoetryTemplate? _selectedTemplate;
  PoetryTemplate? get selectedTemplate => _selectedTemplate;

  // 편집 중인 시
  Poetry? _editingPoetry;
  Poetry? get editingPoetry => _editingPoetry;

  // 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 오류 메시지
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 새로운 창작 과정을 시작합니다
  Future<void> startNewCreation() async {
    _currentStep = CreationStep.wordSelection;
    _sequentialStep = 0;
    _selectedWords.clear();
    _generatedTemplates.clear();
    _selectedTemplate = null;
    _editingPoetry = null;
    _setError(null);
    
    await loadRandomWords();
  }

  /// 무작위 단어들을 로드합니다
  Future<void> loadRandomWords() async {
    try {
      _setLoading(true);
      _currentWords = await _wordService.getRandomWords();
      notifyListeners();
    } catch (e) {
      _setError('단어를 불러오는데 실패했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 단어를 선택합니다 (순차적 선택)
  void selectWordSequentially(Word word) {
    if (_selectedWords.length < 3) {
      _selectedWords.add(word);
      _sequentialStep++;
      
      if (_selectedWords.length == 3) {
        _generateTemplates();
      } else {
        loadRandomWords(); // 다음 단계를 위한 새로운 단어들 로드
      }
      
      notifyListeners();
    }
  }

  /// 단어를 선택합니다 (일괄 선택 - 라디오 버튼용)
  void selectWords(List<Word> words) {
    _selectedWords = words;
    notifyListeners();
    _generateTemplates();
  }

  /// 템플릿을 생성합니다
  Future<void> _generateTemplates() async {
    try {
      _setLoading(true);
      _currentStep = CreationStep.templateSelection;
      
      final keywords = _selectedWords.map((w) => w.text).toList();
      _generatedTemplates = await _poetryService.generatePoetryTemplates(keywords);
      
      notifyListeners();
    } catch (e) {
      _setError('시 템플릿 생성에 실패했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 템플릿을 선택하고 편집 단계로 이동합니다
  void selectTemplate(PoetryTemplate template) {
    _selectedTemplate = template;
    _currentStep = CreationStep.editing;
    
    // 편집용 Poetry 객체 생성
    _editingPoetry = Poetry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: template.title,
      content: template.content,
      keywords: template.keywords,
      createdAt: DateTime.now(),
      isFromTemplate: true,
      templateId: template.id,
    );
    
    notifyListeners();
  }

  /// 시의 내용을 업데이트합니다
  void updatePoetryContent(String title, String content) {
    if (_editingPoetry != null) {
      _editingPoetry = _editingPoetry!.copyWith(
        title: title,
        content: content,
        modifiedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// 시를 저장합니다
  Future<void> savePoetry() async {
    if (_editingPoetry == null) return;
    
    try {
      _setLoading(true);
      await _storageService.savePoetry(_editingPoetry!);
      _currentStep = CreationStep.completed;
      notifyListeners();
    } catch (e) {
      _setError('시 저장에 실패했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 에러를 클리어합니다
  void clearError() {
    _setError(null);
  }
}
