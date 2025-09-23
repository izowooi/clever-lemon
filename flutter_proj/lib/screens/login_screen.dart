import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/implementations/supabase_google_auth_adapter.dart';
import '../services/implementations/supabase_apple_auth_adapter.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SupabaseGoogleAuthAdapter _googleAuthAdapter = SupabaseGoogleAuthAdapter();
  final SupabaseAppleAuthAdapter _appleAuthAdapter = SupabaseAppleAuthAdapter();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _googleAuthAdapter.initialize();
    _appleAuthAdapter.initialize();
  }

  Future<bool> _cancelWithdrawal() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ 탈퇴 취소 실패: 로그인된 사용자가 없습니다.');
        return false;
      }

      print('🔄 탈퇴 취소 처리 시작 - User ID: ${currentUser.id}');

      // Supabase에서 직접 deleted_at을 null로 업데이트
      await supabase
          .from('users_credits')
          .update({'deleted_at': null})
          .eq('user_id', currentUser.id);

      print('✅ 탈퇴 취소 완료');
      return true;
    } catch (error) {
      print('❌ 탈퇴 취소 오류: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('탈퇴 취소 중 오류가 발생했습니다: ${error.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _googleAuthAdapter.signIn();

      if (result.isSuccess) {
        if (mounted) {
          // 탈퇴 유예기간 유저인지 확인
          final showWithdrawalNotice = result.extra?['show_withdrawal_notice'] == true;

          if (showWithdrawalNotice) {
            // 탈퇴 취소 처리
            final cancelSuccess = await _cancelWithdrawal();
            if (cancelSuccess && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 탈퇴가 취소되었습니다! 계속 서비스를 이용하실 수 있습니다.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 4),
                ),
              );
              // 스낵바가 보이도록 약간의 지연
              await Future.delayed(const Duration(milliseconds: 500));
            }
          } else {
            // 일반 로그인 성공 메시지
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('로그인 성공!'),
                backgroundColor: Colors.green,
              ),
            );
          }

          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그인 실패: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 오류: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _appleAuthAdapter.signIn();

      if (result.isSuccess) {
        if (mounted) {
          // 탈퇴 유예기간 유저인지 확인
          final showWithdrawalNotice = result.extra?['show_withdrawal_notice'] == true;

          if (showWithdrawalNotice) {
            // 탈퇴 취소 처리
            final cancelSuccess = await _cancelWithdrawal();
            if (cancelSuccess && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 탈퇴가 취소되었습니다! 계속 서비스를 이용하실 수 있습니다.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 4),
                ),
              );
              // 스낵바가 보이도록 약간의 지연
              await Future.delayed(const Duration(milliseconds: 500));
            }
          } else {
            // 일반 로그인 성공 메시지
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('로그인 성공!'),
                backgroundColor: Colors.green,
              ),
            );
          }

          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그인 실패: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 오류: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 제목
            const Text(
              'Poetry Writer',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '시를 작성하고 공유해보세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),

            // 구글 로그인 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                label: Text(_isLoading ? '로그인 중...' : 'Google로 계속하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 애플 로그인 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleAppleSignIn,
                  icon: const Icon(Icons.apple, color: Colors.white),
                  label: const Text('Apple로 계속하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // 추가 정보
            const Text(
              '계속 진행하면 이용약관 및 개인정보 처리방침에 동의하는 것으로 간주됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
