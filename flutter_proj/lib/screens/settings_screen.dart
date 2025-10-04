import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/interfaces/auth_api_service.dart';
import '../services/implementations/http_auth_api_service.dart';
import '../providers/font_size_provider.dart';
import '../providers/theme_color_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  User? _currentUser;
  String _loginType = '알 수 없음';
  bool _isLoading = true;
  final AuthApiService _authApiService = HttpAuthApiService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // SharedPreferences에서 저장된 provider 정보 읽기
        String? savedProvider;
        try {
          final prefs = await SharedPreferences.getInstance();
          savedProvider = prefs.getString('login_provider');
          print('🔐 저장된 로그인 provider: $savedProvider');
        } catch (error) {
          print('❌ SharedPreferences 읽기 실패: $error');
        }

        setState(() {
          _currentUser = user;

          // 저장된 provider 정보가 있으면 우선 사용
          if (savedProvider != null) {
            switch (savedProvider) {
              case 'google':
                _loginType = 'Google';
                break;
              case 'apple':
                _loginType = 'Apple';
                break;
              default:
                _loginType = savedProvider;
            }
            print('✅ 저장된 정보로 로그인 타입 설정: $_loginType');
          } else {
            // 저장된 정보가 없으면 기존 방식으로 추정
            print('🔍 저장된 정보가 없어 메타데이터로 추정 시도');

            String? detectedProvider;
            final appMetadata = user.appMetadata;
            if (appMetadata != null) {
              detectedProvider = appMetadata['provider'] as String?;
            }

            // 이메일 도메인으로 추정 (구글인 경우)
            if (detectedProvider == null && user.email != null) {
              if (user.email!.contains('@gmail.com')) {
                detectedProvider = 'google';
              }
            }

            if (detectedProvider != null) {
              switch (detectedProvider) {
                case 'google':
                  _loginType = 'Google';
                  break;
                case 'apple':
                  _loginType = 'Apple';
                  break;
                default:
                  _loginType = detectedProvider;
              }
            } else {
              _loginType = '알 수 없음';
            }
            print('🔍 추정된 로그인 타입: $_loginType');
          }
        });
      }
    } catch (error) {
      print('사용자 정보 로드 오류: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      // SharedPreferences에서 저장된 provider 정보 삭제
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('login_provider');
        print('🔐 저장된 로그인 provider 정보 삭제');
      } catch (error) {
        print('❌ SharedPreferences 삭제 실패: $error');
      }

      await supabase.auth.signOut();
      if (mounted) {
        // 로그아웃 성공 시 로그인 화면으로 이동
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 실패: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showWithdrawDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '회원탈퇴',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '정말로 탈퇴하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '⚠️ 탈퇴가 완료되면 후 복구는 불가능합니다',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• 탈퇴 요청 후 2주 유예 기간이 있습니다',
                style: TextStyle(fontSize: 13),
              ),
              Text(
                '• 유예 기간 동안 다시 로그인하면 탈퇴가 취소됩니다',
                style: TextStyle(fontSize: 13),
              ),
              Text(
                '• 2주 후 모든 데이터가 영구적으로 삭제됩니다',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('탈퇴하기'),
              onPressed: () {
                Navigator.of(context).pop();
                _withdraw();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _withdraw() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인이 필요합니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // JWT 토큰 가져오기
      final session = supabase.auth.currentSession;
      if (session?.accessToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인증 토큰을 찾을 수 없습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 로딩 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('탈퇴 처리 중...'),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final request = WithdrawRequest(accessToken: session!.accessToken);
      final result = await _authApiService.withdraw(request);

      if (mounted) {
        // 로딩 스낵바 제거
        ScaffoldMessenger.of(context).removeCurrentSnackBar();

        if (result.isSuccess) {
          // 탈퇴 성공 시 로그아웃 후 로그인 화면으로 이동
          await supabase.auth.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
            Navigator.of(context).pushReplacementNamed('/login');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('탈퇴 처리 중 오류가 발생했습니다: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 사용자 정보 섹션
            const Text(
              '계정 정보',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 이메일 정보
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.email, color: Colors.blue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '이메일',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _currentUser?.email ?? '이메일을 불러올 수 없습니다',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 로그인 타입 정보
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _loginType == 'Google' ? Icons.g_mobiledata : Icons.apple,
                      color: _loginType == 'Google' ? Colors.red : Colors.black,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '로그인 방식',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _loginType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 화면 설정 섹션
            const Text(
              '화면 설정',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 화면 설정 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 글자 크기 설정
                    Row(
                      children: [
                        const Icon(Icons.text_fields, color: Colors.blue),
                        const SizedBox(width: 16),
                        const Text(
                          '글자 크기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: FontSizeOption.values.map((option) {
                        final currentOption = ref.watch(fontSizeProvider);
                        final isSelected = currentOption == option;
                        return ChoiceChip(
                          label: Text(option.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(fontSizeProvider.notifier).setFontSize(option);
                            }
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // 테마 색상 설정
                    Row(
                      children: [
                        const Icon(Icons.palette, color: Colors.blue),
                        const SizedBox(width: 16),
                        const Text(
                          '테마 색상',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ThemeColorOption.values.map((option) {
                        final currentOption = ref.watch(themeColorProvider);
                        final isSelected = currentOption == option;
                        return ChoiceChip(
                          label: Text(option.label),
                          selected: isSelected,
                          avatar: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: option.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(themeColorProvider.notifier).setThemeColor(option);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 로그아웃 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 탈퇴 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _showWithdrawDialog,
                icon: const Icon(Icons.person_remove),
                label: const Text('회원탈퇴'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 추가 정보
            const Text(
              '로그아웃 시 모든 데이터가 안전하게 저장됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            ],
          ),
        ),
      ),
    );
  }
}
