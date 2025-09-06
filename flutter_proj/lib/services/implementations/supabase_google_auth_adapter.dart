import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/auth_adapter.dart';
import '../../main.dart';

class SupabaseGoogleAuthAdapter implements AuthAdapter {
  static const String googleWebClientId = '1043360097075-nhft1b24f7i4hgq4gsck8id6c8usjt2a.apps.googleusercontent.com';
  static const String googleIosClientId = '1043360097075-7p2ilut5e13t7c5bjni97ag4a9ogtsb9.apps.googleusercontent.com';
  
  GoogleSignIn? _googleSignIn;
  
  @override
  Future<void> initialize() async {
    print('SupabaseGoogleAuthAdapter initialize');
    _googleSignIn = GoogleSignIn(
      clientId: googleIosClientId, // iOS용 클라이언트 ID
      serverClientId: googleWebClientId, // 웹/안드로이드용 클라이언트 ID
    );
  }

  @override
  Future<AuthResult> signIn() async {
    try {
      if (_googleSignIn == null) {
        await initialize();
      }

      // Google Sign-In 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      
      if (googleUser == null) {
        return AuthResult.failure('Google 로그인이 취소되었습니다.');
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        return AuthResult.failure('Google 인증 토큰을 가져올 수 없습니다.');
      }

      // Supabase로 Google 로그인
      final AuthResponse response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
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

        return AuthResult.success(
          'Google 로그인 성공!\n이메일: ${user.email ?? 'N/A'}\nUID: ${user.id}',
          extra: {
            'user_id': user.id,
            'email': user.email,
            'name': user.userMetadata?['full_name'] ?? googleUser.displayName,
            'provider': 'google',
          },
        );
      } else {
        return AuthResult.failure('Supabase 로그인에 실패했습니다.');
      }
    } catch (error) {
      print('SupabaseGoogleAuthAdapter signIn error: ${error.toString()}');
      return AuthResult.failure('Google 로그인 오류: ${error.toString()}');
    }
  }

  @override
  Future<AuthResult> signOut() async {
    try {
      // Google Sign-In 로그아웃
      await _googleSignIn?.signOut();
      
      // Supabase 로그아웃
      await supabase.auth.signOut();
      
      return AuthResult.success('Google 로그아웃 성공');
    } catch (error) {
      return AuthResult.failure('로그아웃 오류: ${error.toString()}');
    }
  }
}