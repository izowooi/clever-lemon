import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';

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

  /// OAuth state 파라미터 생성
  String _generateState() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
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
      // Apple Sign-In 가능 여부 확인
      if (!await SignInWithApple.isAvailable()) {
        return AuthResult.failure('이 기기에서는 Apple 로그인을 사용할 수 없습니다.');
      }

      print('🍎 Apple 로그인 시작 - Platform: ${Platform.isAndroid ? "Android" : "iOS"}');

      // OAuth 파라미터 생성
      final state = _generateState();
      final nonce = _generateNonce();

      print('🔐 생성된 OAuth 파라미터:');
      print('  - State: $state');
      print('  - Nonce: $nonce');

      if (Platform.isAndroid) {
        // Android: Supabase OAuth 플로우 사용 (Chrome Tab에서 CSRF 검증 위함)
        final response = await supabase.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: 'com.izowooi.cleverlemon://auth-callback',
          scopes: 'email name',
        );

        // OAuth 플로우 결과 확인
        if (response) {
          // OAuth 플로우가 성공적으로 시작됨
          // 딥링크로 돌아올 때까지 대기하거나 현재 세션 확인
          await Future.delayed(const Duration(seconds: 2)); // 짧은 대기

          final session = supabase.auth.currentSession;
          if (session?.user != null) {
            final user = session!.user;
            print('Android Apple OAuth 로그인 성공: ${user.id}');

            // Android OAuth의 경우 사용자 상태 확인 후 바로 결과 반환
            return await _processUserLogin(user, null);
          } else {
            return AuthResult.failure('OAuth 로그인 후 세션을 찾을 수 없습니다.');
          }
        } else {
          return AuthResult.failure('OAuth 플로우 시작에 실패했습니다.');
        }
      } else {
        // iOS/macOS에서는 네이티브 Apple Sign-In 사용
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
          state: state,
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
          if (credential.givenName != null && credential.familyName != null) {
            displayName = '${credential.givenName} ${credential.familyName}';
          }

          return await _processUserLogin(user, displayName);
        } else {
          return AuthResult.failure('iOS Apple 로그인에 실패했습니다.');
        }
      }
    } catch (error) {
      print('SupabaseAppleAuthAdapter signIn error: ${error.toString()}');
      
      // 사용자가 취소한 경우
      if (error.toString().contains('The user canceled the authorization')) {
        return AuthResult.failure('Apple 로그인이 취소되었습니다.');
      }
      
      return AuthResult.failure('Apple 로그인 오류: ${error.toString()}');
    }
  }

  /// 사용자 로그인 처리 공통 로직
  Future<AuthResult> _processUserLogin(User user, String? displayName) async {
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
      final supabaseAccessToken = session?.accessToken ?? 'N/A';

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
  }

  @override
  Future<AuthResult> signOut() async {
    try {
      // Supabase 로그아웃
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
        // 사용자가 존재하지 않음
        return const UserStatus(exists: false, isDeleted: false);
      } else {
        // 사용자가 존재함
        final deletedAt = response['deleted_at'] as String?;
        return UserStatus(
          exists: true,
          isDeleted: deletedAt != null,
          deletedAt: deletedAt != null ? DateTime.parse(deletedAt) : null,
        );
      }
    } catch (error) {
      print('사용자 상태 확인 오류: $error');
      // 오류 발생시 신규 유저로 처리
      return const UserStatus(exists: false, isDeleted: false);
    }
  }
}