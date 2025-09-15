import 'dart:convert';
import '../models/poetry.dart';
import 'database.dart';
import 'package:drift/drift.dart';

extension PoemExtensions on Poem {
  /// Drift Poem을 Poetry 모델로 변환
  Poetry toPoetry() {
    List<String> keywordsList = [];
    try {
      final decoded = json.decode(keywords);
      if (decoded is List) {
        keywordsList = decoded.cast<String>();
      }
    } catch (e) {
      // JSON 파싱 실패 시 빈 리스트
      keywordsList = [];
    }

    return Poetry(
      id: id,
      title: title,
      content: content,
      keywords: keywordsList,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      isFromTemplate: isFromTemplate,
      templateId: templateId,
    );
  }
}

extension PoetryExtensions on Poetry {
  /// Poetry 모델을 Drift PoemsCompanion으로 변환
  PoemsCompanion toPoemsCompanion() {
    return PoemsCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      keywords: Value(json.encode(keywords)),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      isFromTemplate: Value(isFromTemplate),
      templateId: Value(templateId),
    );
  }
}
