import '../../models/poetry.dart';

abstract class PoetryStorageService {
  /// 모든 시를 가져옵니다
  Future<List<Poetry>> getAllPoetries();

  /// ID로 특정 시를 가져옵니다
  Future<Poetry?> getPoetryById(String id);

  /// 시를 저장합니다
  Future<void> savePoetry(Poetry poetry);

  /// 시를 업데이트합니다
  Future<void> updatePoetry(Poetry poetry);

  /// 시를 삭제합니다
  Future<void> deletePoetry(String id);

  /// 시를 검색합니다
  Future<List<Poetry>> searchPoetries(String query);
}
