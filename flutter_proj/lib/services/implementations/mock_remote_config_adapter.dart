import 'dart:async';

import '../interfaces/remote_config_adapter.dart';
import '../interfaces/auth_adapter.dart';

Future<T> _delay<T>(T Function() body) async {
  await Future<void>.delayed(const Duration(milliseconds: 300));
  return body();
}

class MockRemoteConfigAdapter implements RemoteConfigAdapter {
  bool _initialized = false;
  Map<String, Object> _defaults = {};
  Map<String, Object> _remote = {
    'welcome_message': '안녕하세요, 원격 설정입니다',
    'feature_enabled': true,
    'max_items': 42,
    'pi_value': 3.14,
  };
  Map<String, Object> _active = {};

  @override
  Future<void> initialize() async {
    await _delay(() {});
    _initialized = true;
  }

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    _defaults = Map<String, Object>.from(defaults);
  }

  @override
  Future<AuthResult> fetchAndActivate() async {
    return _delay(() {
      if (!_initialized) {
        return AuthResult.failure('RemoteConfig: 초기화 필요');
      }
      _active = {
        ..._defaults,
        ..._remote,
      };
      return AuthResult.success('RemoteConfig: fetch + activate 완료');
    });
  }

  @override
  String getString(String key, {String fallback = ''}) {
    final v = _active[key];
    if (v is String) return v;
    return fallback;
  }

  @override
  bool getBool(String key, {bool fallback = false}) {
    final v = _active[key];
    if (v is bool) return v;
    return fallback;
  }

  @override
  int getInt(String key, {int fallback = 0}) {
    final v = _active[key];
    if (v is int) return v;
    return fallback;
  }

  @override
  double getDouble(String key, {double fallback = 0.0}) {
    final v = _active[key];
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return fallback;
  }
}


