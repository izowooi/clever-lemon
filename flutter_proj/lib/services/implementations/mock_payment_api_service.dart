import '../interfaces/payment_api_service.dart';
import '../interfaces/auth_api_service.dart';

class MockPaymentApiService implements PaymentApiService {
  
  @override
  Future<ApiResult<Map<String, dynamic>>> approvePayment(PaymentApproveRequest request) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final mockResponse = {
      'payment_id': request.paymentId,
      'user_id': request.userId,
      'amount': request.amount,
      'status': 'approved',
      'approved_at': DateTime.now().toIso8601String(),
      'transaction_id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
    };

    if (request.amount <= 0) {
      return ApiResult.failure(
        '결제 금액이 올바르지 않습니다.',
        statusCode: 400,
      );
    }

    if (request.paymentId.isEmpty || request.userId.isEmpty) {
      return ApiResult.failure(
        '결제 정보가 올바르지 않습니다.',
        statusCode: 400,
      );
    }

    return ApiResult.success(
      '결제가 승인되었습니다.',
      data: mockResponse,
      statusCode: 200,
    );
  }
}