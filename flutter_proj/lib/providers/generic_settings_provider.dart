import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/remote_config_service.dart';
import 'generic_creation_provider.dart';

// 제네릭 설정 데이터 모델
class GenericSettingsConfig {
  final List<String> styles;
  final List<String> authorStyles;
  final List<int> lengths;

  const GenericSettingsConfig({
    required this.styles,
    required this.authorStyles,
    required this.lengths,
  });

  factory GenericSettingsConfig.fromJson(Map<String, dynamic> json) {
    return GenericSettingsConfig(
      styles: List<String>.from(json['styles'] ?? []),
      authorStyles: List<String>.from(json['author_styles'] ?? []),
      lengths: List<int>.from(json['lengths'] ?? []),
    );
  }
}

// 제네릭 UI 텍스트 모델
class GenericUITexts {
  final String aiGenerating;
  final String loading;
  final String generating;
  final String selectStyle;
  final String selectAuthorStyle;
  final String selectLength;
  final String selectWord1;
  final String selectWord2;
  final String selectWord3;
  final String stepTitle1;
  final String stepTitle2;
  final String stepTitle3;
  final String stepTitle4;
  final String stepTitle5;
  final String stepTitle6;
  final String backButton;
  final String congratulations;
  final String successMessage;
  final String successDetail;
  final String newCreation;

  const GenericUITexts({
    required this.aiGenerating,
    required this.loading,
    required this.generating,
    required this.selectStyle,
    required this.selectAuthorStyle,
    required this.selectLength,
    required this.selectWord1,
    required this.selectWord2,
    required this.selectWord3,
    required this.stepTitle1,
    required this.stepTitle2,
    required this.stepTitle3,
    required this.stepTitle4,
    required this.stepTitle5,
    required this.stepTitle6,
    required this.backButton,
    required this.congratulations,
    required this.successMessage,
    required this.successDetail,
    required this.newCreation,
  });

  factory GenericUITexts.fromJson(Map<String, dynamic> json) {
    return GenericUITexts(
      aiGenerating: json['AI_GEN'] ?? 'AI가 창작하고 있습니다...',
      loading: json['LOADING'] ?? '불러오는 중...',
      generating: json['GENERATING'] ?? '생성하는 중...',
      selectStyle: json['SELECT_STYLE'] ?? '스타일을 선택하세요',
      selectAuthorStyle: json['SELECT_AUTHOR_STYLE'] ?? '작가 스타일을 선택하세요',
      selectLength: json['SELECT_LENGTH'] ?? '길이를 선택하세요',
      selectWord1: json['SELECT_WORD_1'] ?? '첫 번째 단어를 선택하세요',
      selectWord2: json['SELECT_WORD_2'] ?? '두 번째 단어를 선택하세요',
      selectWord3: json['SELECT_WORD_3'] ?? '세 번째 단어를 선택하세요',
      stepTitle1: json['STEP_TITLE_1'] ?? '스타일 선택 (1/6)',
      stepTitle2: json['STEP_TITLE_2'] ?? '작가 스타일 선택 (2/6)',
      stepTitle3: json['STEP_TITLE_3'] ?? '길이 선택 (3/6)',
      stepTitle4: json['STEP_TITLE_4'] ?? '첫 번째 단어 선택 (4/6)',
      stepTitle5: json['STEP_TITLE_5'] ?? '두 번째 단어 선택 (5/6)',
      stepTitle6: json['STEP_TITLE_6'] ?? '세 번째 단어 선택 (6/6)',
      backButton: json['BACK_BUTTON'] ?? '이전 단계로',
      congratulations: json['CONGRATULATIONS'] ?? '축하합니다! 🎉',
      successMessage: json['SUCCESS_MESSAGE'] ?? '개가 성공적으로 저장되었습니다',
      successDetail: json['SUCCESS_DETAIL'] ?? '위에서 방금 생성된 결과들을 확인해보세요!\n작품 목록에서도 언제든 다시 볼 수 있습니다.',
      newCreation: json['NEW_CREATION'] ?? '새로운 창작하기',
    );
  }
}

// RemoteConfig 서비스 프로바이더
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService.instance;
});

// 시 창작 설정 프로바이더
final poetrySettingsConfigProvider = FutureProvider<GenericSettingsConfig>((ref) async {
  final remoteConfig = ref.read(remoteConfigServiceProvider);
  final configData = remoteConfig.getJson('poem_settings_config') ?? {};
  return GenericSettingsConfig.fromJson(configData);
});

// 오늘의 글귀 설정 프로바이더
final dailyVerseSettingsConfigProvider = FutureProvider<GenericSettingsConfig>((ref) async {
  final remoteConfig = ref.read(remoteConfigServiceProvider);
  final configData = remoteConfig.getJson('daily_verse_settings_config') ?? {};
  return GenericSettingsConfig.fromJson(configData);
});

// 시 창작 UI 텍스트 프로바이더
final poetryUITextsProvider = FutureProvider<GenericUITexts>((ref) async {
  final remoteConfig = ref.read(remoteConfigServiceProvider);
  final configData = remoteConfig.getJson('poetry') ?? {};
  return GenericUITexts.fromJson(configData);
});

// 오늘의 글귀 UI 텍스트 프로바이더
final dailyVerseUITextsProvider = FutureProvider<GenericUITexts>((ref) async {
  final remoteConfig = ref.read(remoteConfigServiceProvider);
  final configData = remoteConfig.getJson('daily_verse') ?? {};
  return GenericUITexts.fromJson(configData);
});

// 제네릭 설정 프로바이더 팩토리
FutureProvider<GenericSettingsConfig> getSettingsConfigProvider(CreationType type) {
  return type == CreationType.poetry
      ? poetrySettingsConfigProvider
      : dailyVerseSettingsConfigProvider;
}

// 제네릭 UI 텍스트 프로바이더 팩토리
FutureProvider<GenericUITexts> getUITextsProvider(CreationType type) {
  return type == CreationType.poetry
      ? poetryUITextsProvider
      : dailyVerseUITextsProvider;
}