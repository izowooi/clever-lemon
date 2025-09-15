import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../services/implementations/drift_poetry_service.dart';
import '../services/interfaces/poetry_storage_service.dart';

// 데이터베이스 인스턴스 프로바이더
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Drift 기반 Poetry 서비스 프로바이더
final driftPoetryServiceProvider = Provider<DriftPoetryService>((ref) {
  final database = ref.read(databaseProvider);
  return DriftPoetryService(database);
});

// Poetry 저장 서비스 프로바이더 (Drift 사용)
final poetryStorageServiceProvider = Provider<PoetryStorageService>((ref) {
  return ref.read(driftPoetryServiceProvider);
});
