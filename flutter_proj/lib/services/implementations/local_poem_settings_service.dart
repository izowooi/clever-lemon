import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/poem_settings_service.dart';
import '../../models/poem_settings.dart';

class LocalPoemSettingsService implements PoemSettingsService {
  static const String _settingsKey = 'poem_settings';
  static const String _configKey = 'poem_settings_config';

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
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);

      if (configJson != null) {
        final Map<String, dynamic> json = jsonDecode(configJson);
        return PoemSettingsConfig.fromJson(json);
      }
    } catch (e) {
      // 에러 발생시 기본 설정 반환
    }

    // 기본 설정이 없으면 저장하고 반환
    await _saveDefaultConfig();
    return PoemSettingsConfig.defaultConfig;
  }

  @override
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
    await _saveDefaultConfig();
  }

  Future<void> _saveDefaultConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = jsonEncode(PoemSettingsConfig.defaultConfig.toJson());
    await prefs.setString(_configKey, configJson);
  }
}