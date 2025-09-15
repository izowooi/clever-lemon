// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PoemsTable extends Poems with TableInfo<$PoemsTable, Poem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PoemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keywordsMeta = const VerificationMeta(
    'keywords',
  );
  @override
  late final GeneratedColumn<String> keywords = GeneratedColumn<String>(
    'keywords',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFromTemplateMeta = const VerificationMeta(
    'isFromTemplate',
  );
  @override
  late final GeneratedColumn<bool> isFromTemplate = GeneratedColumn<bool>(
    'is_from_template',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_from_template" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    keywords,
    createdAt,
    modifiedAt,
    isFromTemplate,
    templateId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'poems';
  @override
  VerificationContext validateIntegrity(
    Insertable<Poem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('keywords')) {
      context.handle(
        _keywordsMeta,
        keywords.isAcceptableOrUnknown(data['keywords']!, _keywordsMeta),
      );
    } else if (isInserting) {
      context.missing(_keywordsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('is_from_template')) {
      context.handle(
        _isFromTemplateMeta,
        isFromTemplate.isAcceptableOrUnknown(
          data['is_from_template']!,
          _isFromTemplateMeta,
        ),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Poem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Poem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      keywords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keywords'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      ),
      isFromTemplate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_from_template'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
    );
  }

  @override
  $PoemsTable createAlias(String alias) {
    return $PoemsTable(attachedDatabase, alias);
  }
}

class Poem extends DataClass implements Insertable<Poem> {
  final String id;
  final String title;
  final String content;
  final String keywords;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final bool isFromTemplate;
  final String? templateId;
  const Poem({
    required this.id,
    required this.title,
    required this.content,
    required this.keywords,
    required this.createdAt,
    this.modifiedAt,
    required this.isFromTemplate,
    this.templateId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['keywords'] = Variable<String>(keywords);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || modifiedAt != null) {
      map['modified_at'] = Variable<DateTime>(modifiedAt);
    }
    map['is_from_template'] = Variable<bool>(isFromTemplate);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    return map;
  }

  PoemsCompanion toCompanion(bool nullToAbsent) {
    return PoemsCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      keywords: Value(keywords),
      createdAt: Value(createdAt),
      modifiedAt: modifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedAt),
      isFromTemplate: Value(isFromTemplate),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
    );
  }

  factory Poem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Poem(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      keywords: serializer.fromJson<String>(json['keywords']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime?>(json['modifiedAt']),
      isFromTemplate: serializer.fromJson<bool>(json['isFromTemplate']),
      templateId: serializer.fromJson<String?>(json['templateId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'keywords': serializer.toJson<String>(keywords),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime?>(modifiedAt),
      'isFromTemplate': serializer.toJson<bool>(isFromTemplate),
      'templateId': serializer.toJson<String?>(templateId),
    };
  }

  Poem copyWith({
    String? id,
    String? title,
    String? content,
    String? keywords,
    DateTime? createdAt,
    Value<DateTime?> modifiedAt = const Value.absent(),
    bool? isFromTemplate,
    Value<String?> templateId = const Value.absent(),
  }) => Poem(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    keywords: keywords ?? this.keywords,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt.present ? modifiedAt.value : this.modifiedAt,
    isFromTemplate: isFromTemplate ?? this.isFromTemplate,
    templateId: templateId.present ? templateId.value : this.templateId,
  );
  Poem copyWithCompanion(PoemsCompanion data) {
    return Poem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      keywords: data.keywords.present ? data.keywords.value : this.keywords,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      isFromTemplate: data.isFromTemplate.present
          ? data.isFromTemplate.value
          : this.isFromTemplate,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Poem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('keywords: $keywords, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('isFromTemplate: $isFromTemplate, ')
          ..write('templateId: $templateId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    keywords,
    createdAt,
    modifiedAt,
    isFromTemplate,
    templateId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Poem &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.keywords == this.keywords &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.isFromTemplate == this.isFromTemplate &&
          other.templateId == this.templateId);
}

class PoemsCompanion extends UpdateCompanion<Poem> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> content;
  final Value<String> keywords;
  final Value<DateTime> createdAt;
  final Value<DateTime?> modifiedAt;
  final Value<bool> isFromTemplate;
  final Value<String?> templateId;
  final Value<int> rowid;
  const PoemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.keywords = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.isFromTemplate = const Value.absent(),
    this.templateId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PoemsCompanion.insert({
    required String id,
    required String title,
    required String content,
    required String keywords,
    required DateTime createdAt,
    this.modifiedAt = const Value.absent(),
    this.isFromTemplate = const Value.absent(),
    this.templateId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       content = Value(content),
       keywords = Value(keywords),
       createdAt = Value(createdAt);
  static Insertable<Poem> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? keywords,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<bool>? isFromTemplate,
    Expression<String>? templateId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (keywords != null) 'keywords': keywords,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (isFromTemplate != null) 'is_from_template': isFromTemplate,
      if (templateId != null) 'template_id': templateId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PoemsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? content,
    Value<String>? keywords,
    Value<DateTime>? createdAt,
    Value<DateTime?>? modifiedAt,
    Value<bool>? isFromTemplate,
    Value<String?>? templateId,
    Value<int>? rowid,
  }) {
    return PoemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      keywords: keywords ?? this.keywords,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isFromTemplate: isFromTemplate ?? this.isFromTemplate,
      templateId: templateId ?? this.templateId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (keywords.present) {
      map['keywords'] = Variable<String>(keywords.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (isFromTemplate.present) {
      map['is_from_template'] = Variable<bool>(isFromTemplate.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('keywords: $keywords, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('isFromTemplate: $isFromTemplate, ')
          ..write('templateId: $templateId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PoemsTable poems = $PoemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [poems];
}

typedef $$PoemsTableCreateCompanionBuilder =
    PoemsCompanion Function({
      required String id,
      required String title,
      required String content,
      required String keywords,
      required DateTime createdAt,
      Value<DateTime?> modifiedAt,
      Value<bool> isFromTemplate,
      Value<String?> templateId,
      Value<int> rowid,
    });
typedef $$PoemsTableUpdateCompanionBuilder =
    PoemsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> content,
      Value<String> keywords,
      Value<DateTime> createdAt,
      Value<DateTime?> modifiedAt,
      Value<bool> isFromTemplate,
      Value<String?> templateId,
      Value<int> rowid,
    });

class $$PoemsTableFilterComposer extends Composer<_$AppDatabase, $PoemsTable> {
  $$PoemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFromTemplate => $composableBuilder(
    column: $table.isFromTemplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PoemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PoemsTable> {
  $$PoemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFromTemplate => $composableBuilder(
    column: $table.isFromTemplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PoemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PoemsTable> {
  $$PoemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get keywords =>
      $composableBuilder(column: $table.keywords, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFromTemplate => $composableBuilder(
    column: $table.isFromTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );
}

class $$PoemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PoemsTable,
          Poem,
          $$PoemsTableFilterComposer,
          $$PoemsTableOrderingComposer,
          $$PoemsTableAnnotationComposer,
          $$PoemsTableCreateCompanionBuilder,
          $$PoemsTableUpdateCompanionBuilder,
          (Poem, BaseReferences<_$AppDatabase, $PoemsTable, Poem>),
          Poem,
          PrefetchHooks Function()
        > {
  $$PoemsTableTableManager(_$AppDatabase db, $PoemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PoemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PoemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PoemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> keywords = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> modifiedAt = const Value.absent(),
                Value<bool> isFromTemplate = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PoemsCompanion(
                id: id,
                title: title,
                content: content,
                keywords: keywords,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                isFromTemplate: isFromTemplate,
                templateId: templateId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String content,
                required String keywords,
                required DateTime createdAt,
                Value<DateTime?> modifiedAt = const Value.absent(),
                Value<bool> isFromTemplate = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PoemsCompanion.insert(
                id: id,
                title: title,
                content: content,
                keywords: keywords,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                isFromTemplate: isFromTemplate,
                templateId: templateId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PoemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PoemsTable,
      Poem,
      $$PoemsTableFilterComposer,
      $$PoemsTableOrderingComposer,
      $$PoemsTableAnnotationComposer,
      $$PoemsTableCreateCompanionBuilder,
      $$PoemsTableUpdateCompanionBuilder,
      (Poem, BaseReferences<_$AppDatabase, $PoemsTable, Poem>),
      Poem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PoemsTableTableManager get poems =>
      $$PoemsTableTableManager(_db, _db.poems);
}
