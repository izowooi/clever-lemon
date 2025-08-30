import 'auth_adapter.dart';

/// Firebase Messaging를 흉내내는 간단한 어댑터 인터페이스
abstract class MessagingAdapter {
  Future<void> initialize();
  Future<AuthResult> subscribeToTopic(String topic);
  Future<AuthResult> unsubscribeFromTopic(String topic);
}


