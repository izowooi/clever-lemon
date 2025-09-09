import 'package:flutter/foundation.dart';
import 'auth_api_service.dart';

@immutable
class PaymentApproveRequest {
  final String paymentId;
  final String userId;
  final double amount;

  const PaymentApproveRequest({
    required this.paymentId,
    required this.userId,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'user_id': userId,
      'amount': amount,
    };
  }
}

abstract class PaymentApiService {
  Future<ApiResult<Map<String, dynamic>>> approvePayment(PaymentApproveRequest request);
}