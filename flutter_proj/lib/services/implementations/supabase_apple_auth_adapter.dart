import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/auth_adapter.dart';
import '../../main.dart';

class SupabaseAppleAuthAdapter implements AuthAdapter {
  
  @override
  Future<void> initialize() async {
    print('SupabaseAppleAuthAdapter initialize');
  }

  @override
  Future<AuthResult> signIn() async {
    try {
      // Apple Sign-In 가능 여부 확인
      if (!await SignInWithApple.isAvailable()) {
        return AuthResult.failure('이 기기에서는 Apple 로그인을 사용할 수 없습니다.');
      }

      // Apple Sign-In 시작
      final AuthorizationCredentialAppleID credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? idToken = credential.identityToken;
      
      if (idToken == null) {
        return AuthResult.failure('Apple 인증 토큰을 가져올 수 없습니다.');
      }

      // Supabase로 Apple 로그인
      final AuthResponse response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );

      if (response.user != null) {
        final user = response.user!;

        // Supabase access token 가져오기
        final session = supabase.auth.currentSession;
        final accessToken = session?.accessToken ?? 'N/A';

        print('Supabase Access Token: $accessToken');

        // JWT 토큰 검증 (. 개수 확인)
        final dotCount = accessToken.split('.').length - 1;
        print('Access Token dots count: $dotCount');

        // JWT 토큰 구조 확인
        if (dotCount == 2) {
          print('✅ This appears to be a valid JWT token');
        } else {
          print('❌ This does not appear to be a valid JWT token');
        }

        // Apple에서 제공하는 이름 정보 처리
        String? displayName;
        if (credential.givenName != null && credential.familyName != null) {
          displayName = '${credential.givenName} ${credential.familyName}';
        }

        return AuthResult.success(
          'Apple 로그인 성공!\n이메일: ${user.email ?? 'N/A'}\nUID: ${user.id}',
          extra: {
            'user_id': user.id,
            'email': user.email,
            'name': displayName ?? user.userMetadata?['full_name'],
            'provider': 'apple',
          },
        );
      } else {
        return AuthResult.failure('Supabase 로그인에 실패했습니다.');
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
}