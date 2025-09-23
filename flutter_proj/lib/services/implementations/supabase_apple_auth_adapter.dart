import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:async';

import '../interfaces/auth_adapter.dart';
import '../interfaces/auth_api_service.dart';
import 'http_auth_api_service.dart';
import '../../main.dart';

class SupabaseAppleAuthAdapter implements AuthAdapter {
  final AuthApiService _authApiService = HttpAuthApiService();

  @override
  Future<void> initialize() async {
    print('SupabaseAppleAuthAdapter initialize');
  }

  /// Apple 로그인용 nonce 생성
  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  @override
  Future<AuthResult> signIn() async {
    try {
      print('🍎 Apple 로그인 시작 - Platform: ${Platform.isAndroid ? "Android" : "iOS"}');

      if (Platform.isAndroid) {
        // Android: Supabase OAuth 플로우 사용
        return await _signInWithOAuthAndroid();
      } else {
        // iOS: 네이티브 Sign in with Apple 사용
        return await _signInWithAppleIOS();
      }
    } catch (error) {
      print('SupabaseAppleAuthAdapter signIn error: ${error.toString()}');
      
      if (error.toString().contains('canceled')) {
        return AuthResult.failure('Apple 로그인이 취소되었습니다.');
      }
      
      return AuthResult.failure('Apple 로그인 오류: ${error.toString()}');
    }
  }

  /// Android용 OAuth 로그인
  Future<AuthResult> _signInWithOAuthAndroid() async {
    print('Android OAuth 플로우 시작');
    
    // Completer를 사용하여 비동기 결과 대기
    final completer = Completer<AuthResult>();
    StreamSubscription? authSubscription;
    Timer? timeoutTimer;
    
    try {
      // 1. Auth state 변경 리스너 설정 (OAuth 시작 전에 설정!)
      authSubscription = supabase.auth.onAuthStateChange.listen(
        (data) async {
          final event = data.event;
          final session = data.session;
          
          print('Auth state 변경: $event');
          
          if (event == AuthChangeEvent.signedIn && session != null) {
            print('로그인 성공 감지: ${session.user.id}');
            
            // 타임아웃 타이머 취소
            timeoutTimer?.cancel();
            
            // 구독 취소
            await authSubscription?.cancel();
            
            // 사용자 처리
            final result = await _processUserLogin(session.user, null);
            
            // Completer가 아직 완료되지 않았다면 완료
            if (!completer.isCompleted) {
              completer.complete(result);
            }
          }
        },
        onError: (error) {
          print('Auth state 리스너 에러: $error');
          timeoutTimer?.cancel();
          authSubscription?.cancel();
          if (!completer.isCompleted) {
            completer.complete(
              AuthResult.failure('인증 상태 확인 실패: $error')
            );
          }
        },
      );
      
      // 2. OAuth 플로우 시작
      final response = await supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.izowooi.cleverlemon://auth-callback',
        scopes: 'email name',
      );
      
      if (!response) {
        // OAuth 시작 실패
        authSubscription?.cancel();
        return AuthResult.failure('OAuth 플로우 시작에 실패했습니다.');
      }
      
      print('OAuth 플로우 시작됨, 사용자 인증 대기 중...');
      
      // 3. 타임아웃 설정 (60초)
      timeoutTimer = Timer(const Duration(seconds: 60), () async {
        print('Apple 로그인 타임아웃');
        await authSubscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(
            AuthResult.failure('Apple 로그인 시간이 초과되었습니다.')
          );
        }
      });
      
      // 4. 인증 완료 대기
      return await completer.future;
      
    } catch (error) {
      print('Android OAuth 에러: $error');
      authSubscription?.cancel();
      timeoutTimer?.cancel();
      
      if (!completer.isCompleted) {
        completer.complete(
          AuthResult.failure('Apple 로그인 실패: $error')
        );
      }
      
      return completer.future;
    }
  }

  /// iOS용 네이티브 Apple Sign In
  Future<AuthResult> _signInWithAppleIOS() async {
    // Apple Sign-In 가능 여부 확인
    if (!await SignInWithApple.isAvailable()) {
      return AuthResult.failure('이 기기에서는 Apple 로그인을 사용할 수 없습니다.');
    }

    print('iOS 네이티브 Apple 로그인 시작');
    
    final nonce = _generateNonce();
    
    try {
      // 네이티브 Apple Sign-In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final String? idToken = credential.identityToken;
      
      if (idToken == null) {
        return AuthResult.failure('Apple 인증 토큰을 가져올 수 없습니다.');
      }

      // Supabase로 Apple 로그인
      final AuthResponse response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: nonce,
      );

      if (response.user != null) {
        final user = response.user!;
        print('iOS Apple 로그인 성공: ${user.id}');

        // Apple에서 제공하는 이름 정보 처리
        String? displayName;
        if (credential.givenName != null || credential.familyName != null) {
          displayName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
        }

        return await _processUserLogin(user, displayName);
      } else {
        return AuthResult.failure('iOS Apple 로그인에 실패했습니다.');
      }
    } catch (error) {
      if (error.toString().contains('canceled')) {
        return AuthResult.failure('Apple 로그인이 취소되었습니다.');
      }
      throw error;
    }
  }

  /// 사용자 로그인 처리 공통 로직
  Future<AuthResult> _processUserLogin(User user, String? displayName) async {
    try {
      // 사용자 상태 확인
      final userStatusResult = await _checkUserStatus(user.id);

      if (userStatusResult.exists && !userStatusResult.isDeleted) {
        // 케이스 2: 기존 유저, 탈퇴하지 않음 - 바로 로그인 진행
        print('기존 유저 로그인 진행');
        return AuthResult.success(
          'Apple 로그인 성공!\n이메일: ${user.email ?? 'N/A'}\nUID: ${user.id}',
          extra: {
            'user_id': user.id,
            'email': user.email,
            'name': displayName ?? user.userMetadata?['full_name'],
            'provider': 'apple',
            'user_status': 'existing',
          },
        );
      } else if (userStatusResult.exists && userStatusResult.isDeleted) {
        // 케이스 3: 탈퇴 유예기간 유저 - 알림 표시 후 정상 로그인 진행
        print('탈퇴 유예기간 유저 - 알림 표시 후 로그인 진행');
        return AuthResult.success(
          'Apple 로그인 성공!\n탈퇴 신청된 계정입니다. 로그인하여 탈퇴를 취소할 수 있습니다.\n이메일: ${user.email ?? 'N/A'}\nUID: ${user.id}',
          extra: {
            'user_id': user.id,
            'email': user.email,
            'name': displayName ?? user.userMetadata?['full_name'],
            'provider': 'apple',
            'user_status': 'pending_withdrawal',
            'show_withdrawal_notice': true,
          },
        );
      } else {
        // 케이스 1: 신규 유저 - 회원가입 API 호출
        print('신규 유저 회원가입 진행');
        final session = supabase.auth.currentSession;
        
        if (session == null) {
          return AuthResult.failure('세션을 찾을 수 없습니다.');
        }
        
        final supabaseAccessToken = session.accessToken;
        final registerRequest = RegisterRequest(accessToken: supabaseAccessToken);
        final registerResult = await _authApiService.register(registerRequest);

        if (registerResult.isSuccess) {
          print('회원가입 API 호출 성공: ${registerResult.message}');
          return AuthResult.success(
            'Apple 로그인 성공!\n이메일: ${user.email ?? 'N/A'}\nUID: ${user.id}',
            extra: {
              'user_id': user.id,
              'email': user.email,
              'name': displayName ?? user.userMetadata?['full_name'],
              'provider': 'apple',
              'user_status': 'new',
              'register_result': registerResult,
            },
          );
        } else {
          print('회원가입 API 호출 실패: ${registerResult.message}');
          // 회원가입 실패시 Supabase 로그아웃
          await supabase.auth.signOut();
          return AuthResult.failure('회원가입 실패: ${registerResult.message}');
        }
      }
    } catch (error) {
      print('사용자 처리 중 오류: $error');
      return AuthResult.failure('로그인 처리 실패: $error');
    }
  }

  @override
  Future<AuthResult> signOut() async {
    try {
      await supabase.auth.signOut();
      return AuthResult.success('Apple 로그아웃 성공');
    } catch (error) {
      return AuthResult.failure('로그아웃 오류: ${error.toString()}');
    }
  }

  Future<UserStatus> _checkUserStatus(String userId) async {
    try {
      final response = await supabase
          .from('users_credits')
          .select('user_id, deleted_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return const UserStatus(exists: false, isDeleted: false);
      } else {
        final deletedAt = response['deleted_at'] as String?;
        return UserStatus(
          exists: true,
          isDeleted: deletedAt != null,
          deletedAt: deletedAt != null ? DateTime.parse(deletedAt) : null,
        );
      }
    } catch (error) {
      print('사용자 상태 확인 오류: $error');
      return const UserStatus(exists: false, isDeleted: false);
    }
  }
}

// UserStatus 클래스 (필요한 경우)
class UserStatus {
  final bool exists;
  final bool isDeleted;
  final DateTime? deletedAt;

  const UserStatus({
    required this.exists,
    required this.isDeleted,
    this.deletedAt,
  });
}