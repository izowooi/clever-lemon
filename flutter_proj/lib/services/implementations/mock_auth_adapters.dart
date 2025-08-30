import 'dart:async';

import '../interfaces/auth_adapter.dart';

/// 공통 모킹 유틸리티
Future<T> _delay<T>(T Function() body) async {
  await Future<void>.delayed(const Duration(milliseconds: 300));
  return body();
}

class GoogleAuthAdapter implements AuthAdapter {
  bool _initialized = false;
  bool _signedIn = false;

  @override
  Future<void> initialize() async {
    await _delay(() {});
    _initialized = true;
  }

  @override
  Future<AuthResult> signIn() async {
    return _delay(() {
      if (!_initialized) {
        return AuthResult.failure('Google: 초기화 필요');
      }
      _signedIn = true;
      return AuthResult.success('Google: 로그인 성공', extra: {
        'userId': 'google_mock_user',
      });
    });
  }

  @override
  Future<AuthResult> signOut() async {
    return _delay(() {
      if (!_initialized) {
        return AuthResult.failure('Google: 초기화 필요');
      }
      if (!_signedIn) {
        return AuthResult.failure('Google: 이미 로그아웃 상태');
      }
      _signedIn = false;
      return AuthResult.success('Google: 로그아웃 성공');
    });
  }
}

class AppleAuthAdapter implements AuthAdapter {
  bool _initialized = false;
  bool _signedIn = false;

  @override
  Future<void> initialize() async {
    await _delay(() {});
    _initialized = true;
  }

  @override
  Future<AuthResult> signIn() async {
    return _delay(() {
      if (!_initialized) {
        return AuthResult.failure('Apple: 초기화 필요');
      }
      _signedIn = true;
      return AuthResult.success('Apple: 로그인 성공', extra: {
        'userId': 'apple_mock_user',
      });
    });
  }

  @override
  Future<AuthResult> signOut() async {
    return _delay(() {
      if (!_initialized) {
        return AuthResult.failure('Apple: 초기화 필요');
      }
      if (!_signedIn) {
        return AuthResult.failure('Apple: 이미 로그아웃 상태');
      }
      _signedIn = false;
      return AuthResult.success('Apple: 로그아웃 성공');
    });
  }
}

class GuestAuthAdapter implements AuthAdapter {
  bool _initialized = false;
  bool _signedIn = false;

  @override
  Future<void> initialize() async {
    await _delay(() {});
    _initialized = true;
  }

  @override
  Future<AuthResult> signIn() async {
    return _delay(() {
      if (!_initialized) {
        return AuthResult.failure('Guest: 초기화 필요');
      }
      _signedIn = true;
      return AuthResult.success('Guest: 로그인 성공', extra: {
        'userId': 'guest_mock_user',
      });
    });
  }

  @override
  Future<AuthResult> signOut() async {
    return _delay(() {
      if (!_initialized) {
        return AuthResult.failure('Guest: 초기화 필요');
      }
      if (!_signedIn) {
        return AuthResult.failure('Guest: 이미 로그아웃 상태');
      }
      _signedIn = false;
      return AuthResult.success('Guest: 로그아웃 성공');
    });
  }
}


