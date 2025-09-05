import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';

// Supabase 설정
const supabaseUrl = 'https://tnihnfuwhhtvbkmhwiut.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRuaWhuZnV3aGh0dmJrbWh3aXV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY2OTk1NzQsImV4cCI6MjA3MjI3NTU3NH0.jdCN5EwpBrIoU-vUzaax6MRZRme4YuVxFb_J-UGwbvg';

// Supabase 클라이언트 인스턴스 (전역 사용)
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: PoetryWriterApp(),
    ),
  );
}

class PoetryWriterApp extends StatelessWidget {
  const PoetryWriterApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const HomeScreen(),
    );
  }
}
