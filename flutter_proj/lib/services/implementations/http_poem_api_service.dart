import 'dart:convert';
import 'package:http/http.dart' as http;

import '../interfaces/poem_api_service.dart';
import '../interfaces/auth_api_service.dart';

class HttpPoemApiService implements PoemApiService {
  static const String baseUrl = 'https://clever-lemon.zowoo.uk';
  
  @override
  Future<ApiResult<Map<String, dynamic>>> generatePoem(PoemGenerateRequest request) async {
    try {
      final url = Uri.parse('$baseUrl/poems/generate');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      final responseBody = response.body.isNotEmpty 
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResult.success(
          '시 생성이 완료되었습니다.',
          data: responseBody,
          statusCode: response.statusCode,
        );
      } else {
        final errorMessage = responseBody['message'] as String? ?? 
                           responseBody['error'] as String? ?? 
                           'Unknown error occurred';
        return ApiResult.failure(
          '시 생성 실패: $errorMessage',
          statusCode: response.statusCode,
        );
      }
    } catch (error) {
      return ApiResult.failure('네트워크 오류: ${error.toString()}');
    }
  }
}