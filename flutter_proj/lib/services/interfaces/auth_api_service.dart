import 'package:flutter/foundation.dart';

@immutable
class RegisterRequest {
  final String accessToken;

  const RegisterRequest({
    required this.accessToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
    };
  }
}

@immutable
class WithdrawRequest {
  final String accessToken;

  const WithdrawRequest({
    required this.accessToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
    };
  }
}

@immutable
class UserStatus {
  final bool exists;
  final bool isDeleted;
  final DateTime? deletedAt;

  const UserStatus({
    required this.exists,
    required this.isDeleted,
    this.deletedAt,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      exists: json['exists'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
    );
  }
}

@immutable
class ApiResult<T> {
  final bool isSuccess;
  final String message;
  final T? data;
  final int? statusCode;

  const ApiResult({
    required this.isSuccess,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResult.success(String message, {T? data, int? statusCode}) {
    return ApiResult(
      isSuccess: true,
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResult.failure(String message, {int? statusCode}) {
    return ApiResult(
      isSuccess: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

abstract class AuthApiService {
  Future<ApiResult<Map<String, dynamic>>> register(RegisterRequest request);
  Future<ApiResult<Map<String, dynamic>>> withdraw(WithdrawRequest request);
}