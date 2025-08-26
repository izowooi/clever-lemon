import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/poetry_creation_provider.dart';
import 'providers/poetry_list_provider.dart';
import 'services/interfaces/word_service.dart';
import 'services/interfaces/poetry_service.dart';
import 'services/interfaces/storage_service.dart';
import 'services/implementations/mock_word_service.dart';
import 'services/implementations/mock_poetry_service.dart';
import 'services/implementations/local_storage_service.dart';

void main() {
  runApp(const PoetryWriterApp());
}

class PoetryWriterApp extends StatelessWidget {
  const PoetryWriterApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 서비스 인스턴스 생성 (의존성 주입)
    final WordService wordService = MockWordService();
    final PoetryService poetryService = MockPoetryService();
    final StorageService storageService = LocalStorageService();

    return MultiProvider(
      providers: [
        // Provider로 서비스들을 등록
        Provider<WordService>.value(value: wordService),
        Provider<PoetryService>.value(value: poetryService),
        Provider<StorageService>.value(value: storageService),
        
        // ChangeNotifierProvider로 상태 관리 클래스들을 등록
        ChangeNotifierProvider<PoetryCreationProvider>(
          create: (context) => PoetryCreationProvider(
            wordService: wordService,
            poetryService: poetryService,
            storageService: storageService,
          )..startNewCreation(), // 앱 시작 시 초기화
        ),
        ChangeNotifierProvider<PoetryListProvider>(
          create: (context) => PoetryListProvider(
            storageService: storageService,
          ),
        ),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
