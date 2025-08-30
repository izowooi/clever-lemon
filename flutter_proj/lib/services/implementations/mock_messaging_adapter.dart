import 'dart:async';

import '../interfaces/messaging_adapter.dart';
import '../interfaces/auth_adapter.dart';

Future<T> _delay<T>(T Function() body) async {
  await Future<void>.delayed(const Duration(milliseconds: 250));
  return body();
}

class MockMessagingAdapter implements MessagingAdapter {
  bool _initialized = false;
  final Set<String> _topics = <String>{};

  Set<String> get topics => _topics;

  @override
  Future<void> initialize() async {
    await _delay(() {});
    _initialized = true;
  }

  @override
  Future<AuthResult> subscribeToTopic(String topic) async {
    return _delay(() {
      if (!_initialized) {
        return AuthResult.failure('Messaging: 초기화 필요');
      }
      if (topic.trim().isEmpty) {
        return AuthResult.failure('Messaging: 토픽이 비어있습니다');
      }
      _topics.add(topic);
      return AuthResult.success('Messaging: 구독 완료', extra: {
        'topics': _topics.toList(),
      });
    });
  }

  @override
  Future<AuthResult> unsubscribeFromTopic(String topic) async {
    return _delay(() {
      if (!_initialized) {
        return AuthResult.failure('Messaging: 초기화 필요');
      }
      if (topic.trim().isEmpty) {
        return AuthResult.failure('Messaging: 토픽이 비어있습니다');
      }
      final removed = _topics.remove(topic);
      if (!removed) {
        return AuthResult.failure('Messaging: 구독 중이 아닌 토픽');
      }
      return AuthResult.success('Messaging: 구독 해제 완료', extra: {
        'topics': _topics.toList(),
      });
    });
  }
}


