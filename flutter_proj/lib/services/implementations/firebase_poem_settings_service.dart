import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/poem_settings_service.dart';
import '../implementations/firebase_remote_config_adapter.dart';
import '../../models/poem_settings.dart';

class FirebasePoemSettingsService implements PoemSettingsService {
  static const String _settingsKey = 'poem_settings';
  final FirebaseRemoteConfigAdapter _remoteConfigAdapter;

  FirebasePoemSettingsService(this._remoteConfigAdapter);

  @override
  Future<PoemSettings> getCurrentSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> json = jsonDecode(settingsJson);
        return PoemSettings.fromJson(json);
      }
    } catch (e) {
      // 에러 발생시 기본값 반환
    }

    return PoemSettings.defaultSettings;
  }

  @override
  Future<void> saveSettings(PoemSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, settingsJson);
  }

  @override
  Future<PoemSettingsConfig> getSettingsConfig() async {
    try {
      // Firebase Remote Config에서 설정을 가져온다
      final configData = _remoteConfigAdapter.getPoemSettingsConfig();

      if (configData != null) {
        // JSON 형식을 PoemSettingsConfig로 변환
        // assets/poem_settings_config.json 형식: lengths가 문자열 배열
        final rawLengths = configData['lengths'] as List?;
        final lengths = <int>[];

        if (rawLengths != null) {
          for (final lengthStr in rawLengths) {
            if (lengthStr is String) {
              // "4행" -> 4 로 변환
              final numStr = lengthStr.replaceAll('행', '');
              final num = int.tryParse(numStr);
              if (num != null) {
                lengths.add(num);
              }
            } else if (lengthStr is int) {
              lengths.add(lengthStr);
            }
          }
        }

        return PoemSettingsConfig(
          styles: List<String>.from(configData['styles'] as List? ?? []),
          authorStyles: List<String>.from(configData['authorStyles'] as List? ?? []),
          lengths: lengths,
        );
      }
    } catch (e) {
      print('[FirebasePoemSettingsService] Remote Config에서 설정 가져오기 실패: $e');
    }

    // Remote Config 실패시 기본값 반환
    return PoemSettingsConfig.defaultConfig;
  }

  @override
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }
}