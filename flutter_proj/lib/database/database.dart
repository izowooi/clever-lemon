import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Poetry 테이블 정의
class Poems extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get keywords => text()(); // JSON 문자열로 저장
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime().nullable()();
  BoolColumn get isFromTemplate => boolean().withDefault(const Constant(false))();
  TextColumn get templateId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Poems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Poetry 관련 쿼리 메서드들
  Future<List<Poem>> getAllPoems() => select(poems).get();
  
  Future<List<Poem>> getPoemsByKeyword(String keyword) {
    return (select(poems)
      ..where((tbl) => tbl.keywords.contains(keyword))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<Poem?> getPoemById(String id) {
    return (select(poems)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertPoem(PoemsCompanion poem) {
    return into(poems).insert(poem);
  }

  Future<bool> updatePoem(PoemsCompanion poem) {
    return update(poems).replace(poem);
  }

  Future<int> deletePoem(String id) {
    return (delete(poems)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<Poem>> getRecentPoems({int limit = 10}) {
    return (select(poems)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit))
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'poems.db'));
    return NativeDatabase.createInBackground(file);
  });
}
