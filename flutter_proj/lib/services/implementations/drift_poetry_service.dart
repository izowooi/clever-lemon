import '../../models/poetry.dart';
import '../interfaces/poetry_storage_service.dart';
import '../../database/database.dart';
import '../../database/poem_extensions.dart';

class DriftPoetryService implements PoetryStorageService {
  final AppDatabase _database;

  DriftPoetryService(this._database);

  @override
  Future<List<Poetry>> getAllPoetries() async {
    final poems = await _database.getAllPoems();
    return poems.map((poem) => poem.toPoetry()).toList();
  }

  @override
  Future<Poetry?> getPoetryById(String id) async {
    final poem = await _database.getPoemById(id);
    return poem?.toPoetry();
  }

  @override
  Future<void> savePoetry(Poetry poetry) async {
    await _database.insertPoem(poetry.toPoemsCompanion());
  }

  @override
  Future<void> updatePoetry(Poetry poetry) async {
    await _database.updatePoem(poetry.toPoemsCompanion());
  }

  @override
  Future<void> deletePoetry(String id) async {
    await _database.deletePoem(id);
  }

  @override
  Future<List<Poetry>> searchPoetries(String query) async {
    final poems = await _database.getPoemsByKeyword(query);
    return poems.map((poem) => poem.toPoetry()).toList();
  }

  /// 최근 작성된 시들을 가져옵니다
  Future<List<Poetry>> getRecentPoetries({int limit = 10}) async {
    final poems = await _database.getRecentPoems(limit: limit);
    return poems.map((poem) => poem.toPoetry()).toList();
  }
}
