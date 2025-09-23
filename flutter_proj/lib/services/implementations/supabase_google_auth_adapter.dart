import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/auth_adapter.dart';
import '../interfaces/auth_api_service.dart';
import 'http_auth_api_service.dart';
import '../../main.dart';

class SupabaseGoogleAuthAdapter implements AuthAdapter {
  static const String googleWebClientId = '1043360097075-nhft1b24f7i4hgq4gsck8id6c8usjt2a.apps.googleusercontent.com';
  static const String googleIosClientId = '1043360097075-7p2ilut5e13t7c5bjni97ag4a9ogtsb9.apps.googleusercontent.com';
  
  GoogleSignIn? _googleSignIn;
  final AuthApiService _authApiService = HttpAuthApiService();
  
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
        print('Supabase 로그인 성공: ${user.id}');

        // 사용자 상태 확인
        final userStatusResult = await _checkUserStatus(user.id);

        if (userStatusResult.exists && !userStatusResult.isDeleted) {
          // 케이스 2: 기존 유저, 탈퇴하지 않음 - 바로 로그인 진행
          print('기존 유저 로그인 진행');
          return AuthResult.success(
            'Google 로그인 성공!\n이메일: ${user.email ?? 'N/A'}\nUID: ${user.id}',
            extra: {
              'user_id': user.id,
              'email': user.email,
              'name': user.userMetadata?['full_name'] ?? googleUser.displayName,
              'provider': 'google',
              'user_status': 'existing',
            },
          );
        } else if (userStatusResult.exists && userStatusResult.isDeleted) {
          // 케이스 3: 탈퇴 유예기간 유저 - 알림 표시 후 정상 로그인 진행
          print('탈퇴 유예기간 유저 - 알림 표시 후 로그인 진행');

          return AuthResult.success(
            'Google 로그인 성공!\n탈퇴 신청된 계정입니다. 로그인하여 탈퇴를 취소할 수 있습니다.\n이메일: ${user.email ?? 'N/A'}\nUID: ${user.id}',
            extra: {
              'user_id': user.id,
              'email': user.email,
              'name': user.userMetadata?['full_name'] ?? googleUser.displayName,
              'provider': 'google',
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
              'Google 로그인 성공!\n이메일: ${user.email ?? 'N/A'}\nUID: ${user.id}',
              extra: {
                'user_id': user.id,
                'email': user.email,
                'name': user.userMetadata?['full_name'] ?? googleUser.displayName,
                'provider': 'google',
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