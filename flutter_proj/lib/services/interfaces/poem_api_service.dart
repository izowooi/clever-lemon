import 'package:flutter/foundation.dart';
import 'auth_api_service.dart';

@immutable
class PoemGenerateRequest {
  final String userId;
  final String style;
  final String authorStyle;
  final List<String> keywords;
  final String length;

  const PoemGenerateRequest({
    required this.userId,
    required this.style,
    required this.authorStyle,
    required this.keywords,
    required this.length,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'style': style,
      'author_style': authorStyle,
      'keywords': keywords,
      'length': length,
    };
  }
}

abstract class PoemApiService {
  Future<ApiResult<Map<String, dynamic>>> generatePoem(PoemGenerateRequest request);
}