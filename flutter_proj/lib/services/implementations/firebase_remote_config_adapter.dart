import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_core/firebase_core.dart';

import '../interfaces/remote_config_adapter.dart';
import '../interfaces/auth_adapter.dart';

class FirebaseRemoteConfigAdapter implements RemoteConfigAdapter {
  bool _initialized = false;
  FirebaseRemoteConfig? _remoteConfig;

  @override
  Future<void> initialize() async {
    try {
      print('[RemoteConfigAdapter] 초기화 시작');
      
      // Firebase가 초기화되었는지 확인
      if (Firebase.apps.isEmpty) {
        print('[RemoteConfigAdapter] Firebase 앱이 없음 - 초기화 필요');
        throw Exception('Firebase가 초기화되지 않음');
      }
      
      _remoteConfig = FirebaseRemoteConfig.instance;
      print('[RemoteConfigAdapter] FirebaseRemoteConfig.instance 획득 완료');
      
      // Remote Config 설정
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      print('[RemoteConfigAdapter] Remote Config 설정 완료');
      
      _initialized = true;
      print('[RemoteConfigAdapter] 초기화 성공');
    } catch (e) {
      print('[RemoteConfigAdapter] 초기화 실패: $e');
      print('[RemoteConfigAdapter] 스택 트레이스: ${StackTrace.current}');
      _initialized = false;
      rethrow;
    }
  }

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    if (!_initialized || _remoteConfig == null) {
      throw Exception('RemoteConfig: 초기화 필요');
    }
    
    try {
      print('[RemoteConfigAdapter] 기본값 설정 시작: $defaults');
      await _remoteConfig!.setDefaults(defaults);
      print('[RemoteConfigAdapter] 기본값 설정 완료');
    } catch (e) {
      print('[RemoteConfigAdapter] 기본값 설정 실패: $e');
      rethrow;
    }
  }

  @override
  Future<AuthResult> fetchAndActivate() async {
    if (!_initialized || _remoteConfig == null) {
      return AuthResult.failure('RemoteConfig: 초기화 필요');
    }

    try {
      print('[RemoteConfigAdapter] fetchAndActivate 시작');
      
      final bool updated = await _remoteConfig!.fetchAndActivate();
      
      print('[RemoteConfigAdapter] fetchAndActivate 완료 - 업데이트됨: $updated');
      
      // 현재 값들 로그 출력
      final reviewVersionAos = getReviewVersionAos();
      final reviewVersionIos = getReviewVersionIos();
      final apiBaseUrl = getApiBaseUrl();
      final poemSettingsConfig = getPoemSettingsConfig();

      print('[RemoteConfigAdapter] 현재 값들:');
      print('  - review_versioncode_aos: $reviewVersionAos');
      print('  - review_versioncode_ios: $reviewVersionIos');
      print('  - api_base_url: $apiBaseUrl');
      print('  - poem_settings_config: $poemSettingsConfig');
      
      return AuthResult.success(
        'RemoteConfig: fetch + activate 완료 (업데이트: $updated)',
        extra: {
          'updated': updated,
          'review_versioncode_aos': reviewVersionAos,
          'review_versioncode_ios': reviewVersionIos,
          'api_base_url': apiBaseUrl,
          'poem_settings_config': poemSettingsConfig,
          'last_fetch_time': _remoteConfig!.lastFetchTime.toIso8601String(),
          'last_fetch_status': _remoteConfig!.lastFetchStatus.toString(),
        },
      );
    } catch (e) {
      print('[RemoteConfigAdapter] fetchAndActivate 실패: $e');
      return AuthResult.failure('RemoteConfig: fetch + activate 실패 - ${e.toString()}');
    }
  }

  @override
  String getString(String key, {String fallback = ''}) {
    if (!_initialized || _remoteConfig == null) {
      print('[RemoteConfigAdapter] getString($key) - 초기화되지 않음, fallback 반환: $fallback');
      return fallback;
    }
    
    final value = _remoteConfig!.getString(key);
    print('[RemoteConfigAdapter] getString($key) = $value');
    return value;
  }

  @override
  bool getBool(String key, {bool fallback = false}) {
    if (!_initialized || _remoteConfig == null) {
      print('[RemoteConfigAdapter] getBool($key) - 초기화되지 않음, fallback 반환: $fallback');
      return fallback;
    }
    
    final value = _remoteConfig!.getBool(key);
    print('[RemoteConfigAdapter] getBool($key) = $value');
    return value;
  }

  @override
  int getInt(String key, {int fallback = 0}) {
    if (!_initialized || _remoteConfig == null) {
      print('[RemoteConfigAdapter] getInt($key) - 초기화되지 않음, fallback 반환: $fallback');
      return fallback;
    }
    
    final value = _remoteConfig!.getInt(key);
    print('[RemoteConfigAdapter] getInt($key) = $value');
    return value;
  }

  @override
  double getDouble(String key, {double fallback = 0.0}) {
    if (!_initialized || _remoteConfig == null) {
      print('[RemoteConfigAdapter] getDouble($key) - 초기화되지 않음, fallback 반환: $fallback');
      return fallback;
    }

    final value = _remoteConfig!.getDouble(key);
    print('[RemoteConfigAdapter] getDouble($key) = $value');
    return value;
  }

  /// JSON 형태의 Remote Config 값을 파싱하여 Map으로 반환
  Map<String, dynamic>? getJson(String key, {Map<String, dynamic>? fallback}) {
    if (!_initialized || _remoteConfig == null) {
      print('[RemoteConfigAdapter] getJson($key) - 초기화되지 않음, fallback 반환');
      return fallback;
    }

    try {
      final jsonString = _remoteConfig!.getString(key);
      if (jsonString.isEmpty) {
        print('[RemoteConfigAdapter] getJson($key) - 빈 문자열, fallback 반환');
        return fallback;
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      print('[RemoteConfigAdapter] getJson($key) - JSON 파싱 성공');
      return jsonData;
    } catch (e) {
      print('[RemoteConfigAdapter] getJson($key) - JSON 파싱 실패: $e, fallback 반환');
      return fallback;
    }
  }

  /// 특정 Remote Config 매개변수 값을 가져오는 헬퍼 메서드들
  String getApiBaseUrl() {
    return getString('api_base_url', fallback: '');
  }

  int getReviewVersionAos() {
    return getInt('review_versioncode_aos', fallback: 0);
  }

  int getReviewVersionIos() {
    return getInt('review_versioncode_ios', fallback: 0);
  }

  /// 시 설정 JSON 구성을 가져오는 메서드
  Map<String, dynamic>? getPoemSettingsConfig() {
    return getJson('poem_settings_config');
  }

  /// Remote Config 상태 정보를 가져오는 추가 메서드
  Future<AuthResult> getConfigInfo() async {
    if (!_initialized || _remoteConfig == null) {
      return AuthResult.failure('RemoteConfig: 초기화 필요');
    }

    try {
      final info = {
        'last_fetch_time': _remoteConfig!.lastFetchTime.toIso8601String(),
        'last_fetch_status': _remoteConfig!.lastFetchStatus.toString(),
        'settings': {
          'fetch_timeout': _remoteConfig!.settings.fetchTimeout.inSeconds,
          'minimum_fetch_interval': _remoteConfig!.settings.minimumFetchInterval.inSeconds,
        },
      };
      
      return AuthResult.success('RemoteConfig: 상태 정보', extra: info);
    } catch (e) {
      return AuthResult.failure('RemoteConfig: 상태 정보 조회 실패 - ${e.toString()}');
    }
  }
}
