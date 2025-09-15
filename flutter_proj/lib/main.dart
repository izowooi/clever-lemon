import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'config/api_config.dart';
import 'services/remote_config_service.dart';

// Supabase 설정
const supabaseUrl = 'https://tnihnfuwhhtvbkmhwiut.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRuaWhuZnV3aGh0dmJrbWh3aXV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY2OTk1NzQsImV4cCI6MjA3MjI3NTU3NH0.jdCN5EwpBrIoU-vUzaax6MRZRme4YuVxFb_J-UGwbvg';

// Supabase 클라이언트 인스턴스 (전역 사용)
final supabase = Supabase.instance.client;

/// 전역 Firebase Remote Config 서비스에 접근하는 getter
RemoteConfigService get remoteConfigService => RemoteConfigService.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // API 환경 정보 출력
  ApiConfig.printCurrentEnvironment();

  // Firebase 초기화
  await Firebase.initializeApp();

  // Supabase 초기화
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Firebase Remote Config 초기화 및 기본값 설정
  await _initializeRemoteConfig();

  runApp(
    const ProviderScope(
      child: PoetryWriterApp(),
    ),
  );
}

/// Firebase Remote Config를 초기화하고 기본값을 설정합니다
Future<void> _initializeRemoteConfig() async {
  try {
    print('[Main] Firebase Remote Config 초기화 시작');

    final remoteConfig = RemoteConfigService.instance;
    await remoteConfig.initialize();

    // 기본값 설정
    final Map<String, Object> defaultValues = {
      'review_versioncode_aos': 1,
      'review_versioncode_ios': 1,
      'api_base_url': 'https://clever-lemon.zowoo.uk',
      'poem_settings_config': '''{
        "styles": ["낭만적인", "우울한", "철학적인", "초현실적인", "서정적인"],
        "authorStyles": ["김소월", "윤동주", "서정주", "김춘수", "정지용"],
        "lengths": ["4행", "8행", "12행", "16행", "20행"]
      }''',
    };

    await remoteConfig.setDefaults(defaultValues);

    // Remote Config 값 fetch 및 activate
    final success = await remoteConfig.fetchAndActivate();
    if (success) {
      print('[Main] Firebase Remote Config 초기화 완료');
    } else {
      print('[Main] Firebase Remote Config fetch 실패');
    }
  } catch (e) {
    print('[Main] Firebase Remote Config 초기화 실패: $e');
    // 초기화 실패해도 앱은 계속 실행
  }
}

class PoetryWriterApp extends StatefulWidget {
  const PoetryWriterApp({super.key});

  @override
  State<PoetryWriterApp> createState() => _PoetryWriterAppState();
}

class _PoetryWriterAppState extends State<PoetryWriterApp> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // 현재 세션 확인
    final session = supabase.auth.currentSession;

    setState(() {
      _isAuthenticated = session != null;
      _isLoading = false;
    });

    // 인증 상태 변경 리스너 설정
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (mounted) {
        setState(() {
          _isAuthenticated = session != null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Poetry Writer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,

        // 카드 테마
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),

        // 버튼 테마
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // 입력 필드 테마
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      home: _isAuthenticated ? const HomeScreen() : const LoginScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
