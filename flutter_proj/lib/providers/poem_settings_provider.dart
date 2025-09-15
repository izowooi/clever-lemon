import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poem_settings.dart';
import '../services/interfaces/poem_settings_service.dart';
import '../services/implementations/firebase_poem_settings_service.dart';
import '../services/implementations/firebase_remote_config_adapter.dart';
import '../main.dart';

final firebaseRemoteConfigAdapterProvider = Provider<FirebaseRemoteConfigAdapter?>((ref) {
  return globalRemoteConfig;
});

final poemSettingsServiceProvider = Provider<PoemSettingsService>((ref) {
  final remoteConfigAdapter = ref.read(firebaseRemoteConfigAdapterProvider);
  if (remoteConfigAdapter != null) {
    return FirebasePoemSettingsService(remoteConfigAdapter);
  } else {
    // Remote Config가 초기화되지 않은 경우 기본 서비스 사용
    return FirebasePoemSettingsService(FirebaseRemoteConfigAdapter());
  }
});

final poemSettingsProvider = StateNotifierProvider<PoemSettingsNotifier, PoemSettings>((ref) {
  final settingsService = ref.read(poemSettingsServiceProvider);
  return PoemSettingsNotifier(settingsService);
});

final poemSettingsConfigProvider = FutureProvider<PoemSettingsConfig>((ref) async {
  final settingsService = ref.read(poemSettingsServiceProvider);
  return await settingsService.getSettingsConfig();
});

class PoemSettingsNotifier extends StateNotifier<PoemSettings> {
  final PoemSettingsService _settingsService;

  PoemSettingsNotifier(this._settingsService) : super(PoemSettings.defaultSettings) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getCurrentSettings();
      state = settings;
    } catch (e) {
      // 에러 발생시 기본값 유지
      state = PoemSettings.defaultSettings;
    }
  }

  Future<void> updateStyle(String style) async {
    final newSettings = state.copyWith(style: style);
    await _saveSettings(newSettings);
  }

  Future<void> updateAuthorStyle(String authorStyle) async {
    final newSettings = state.copyWith(authorStyle: authorStyle);
    await _saveSettings(newSettings);
  }

  Future<void> updateLength(int length) async {
    final newSettings = state.copyWith(length: length);
    await _saveSettings(newSettings);
  }

  Future<void> updateAllSettings({
    String? style,
    String? authorStyle,
    int? length,
  }) async {
    final newSettings = state.copyWith(
      style: style,
      authorStyle: authorStyle,
      length: length,
    );
    await _saveSettings(newSettings);
  }

  Future<void> resetToDefaults() async {
    try {
      await _settingsService.resetToDefaults();
      state = PoemSettings.defaultSettings;
    } catch (e) {
      // 에러 발생시 기본값으로 설정
      state = PoemSettings.defaultSettings;
    }
  }

  Future<void> _saveSettings(PoemSettings settings) async {
    try {
      await _settingsService.saveSettings(settings);
      state = settings;
    } catch (e) {
      // 저장 실패시 이전 상태 유지
    }
  }
}