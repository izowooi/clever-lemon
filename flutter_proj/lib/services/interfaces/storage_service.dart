import '../../models/poetry.dart';

abstract class StorageService {
  /// 시를 저장합니다.
  Future<void> savePoetry(Poetry poetry);

  /// 저장된 모든 시를 가져옵니다.
  Future<List<Poetry>> getAllPoetries();

  /// 특정 ID의 시를 가져옵니다.
  Future<Poetry?> getPoetryById(String id);

  /// 시를 삭제합니다.
  Future<void> deletePoetry(String id);

  /// 시를 업데이트합니다.
  Future<void> updatePoetry(Poetry poetry);
}
