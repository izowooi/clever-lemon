import 'dart:convert';
import 'package:http/http.dart' as http;

import '../interfaces/auth_api_service.dart';
import '../../config/api_config.dart';

class HttpAuthApiService implements AuthApiService {
  
  @override
  Future<ApiResult<Map<String, dynamic>>> register(RegisterRequest request) async {
    try {
      final url = Uri.parse(ApiConfig.authRegisterUrl);
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
          '회원가입이 완료되었습니다.',
          data: responseBody,
          statusCode: response.statusCode,
        );
      } else {
        final errorMessage = responseBody['message'] as String? ?? 
                           responseBody['error'] as String? ?? 
                           'Unknown error occurred';
        return ApiResult.failure(
          '회원가입 실패: $errorMessage',
          statusCode: response.statusCode,
        );
      }
    } catch (error) {
      return ApiResult.failure('네트워크 오류: ${error.toString()}');
    }
  }
}