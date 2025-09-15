import '../../models/poem_settings.dart';

abstract class PoemSettingsService {
  Future<PoemSettings> getCurrentSettings();
  Future<void> saveSettings(PoemSettings settings);
  Future<PoemSettingsConfig> getSettingsConfig();
  Future<void> resetToDefaults();
}