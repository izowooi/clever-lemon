import 'auth_adapter.dart';

/// Firebase Remote Config를 흉내내는 간단한 어댑터 인터페이스
abstract class RemoteConfigAdapter {
  Future<void> initialize();
  Future<void> setDefaults(Map<String, Object> defaults);
  Future<AuthResult> fetchAndActivate();

  String getString(String key, {String fallback = ''});
  bool getBool(String key, {bool fallback = false});
  int getInt(String key, {int fallback = 0});
  double getDouble(String key, {double fallback = 0.0});
}


