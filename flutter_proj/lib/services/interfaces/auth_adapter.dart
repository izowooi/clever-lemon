import 'package:flutter/foundation.dart';

/// 간단한 인증 어댑터 인터페이스
/// 실제 구현(구글/애플/게스트)은 각자 패키지 별로 구현하세요.
abstract class AuthAdapter {
  /// 어댑터 초기화. 필요 시 SDK 초기화 등 수행
  Future<void> initialize();

  /// 로그인 수행. 성공/실패 여부와 메시지를 반환
  Future<AuthResult> signIn();

  /// 로그아웃 수행. 성공/실패 여부와 메시지를 반환
  Future<AuthResult> signOut();
}

/// 인증 결과를 담는 단순 DTO
@immutable
class AuthResult {
  final bool isSuccess;
  final String message;
  final Map<String, Object?>? extra;

  const AuthResult({
    required this.isSuccess,
    required this.message,
    this.extra,
  });

  factory AuthResult.success(String message, {Map<String, Object?>? extra}) {
    return AuthResult(isSuccess: true, message: message, extra: extra);
  }

  factory AuthResult.failure(String message, {Map<String, Object?>? extra}) {
    return AuthResult(isSuccess: false, message: message, extra: extra);
  }

  @override
  String toString() => 'AuthResult(isSuccess: ' + isSuccess.toString() + ', message: ' + message + ', extra: ' + (extra?.toString() ?? 'null') + ')';
}


