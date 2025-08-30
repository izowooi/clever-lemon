import 'dart:async';

import '../../models/user_info.dart';
import '../interfaces/api_service.dart';

Future<T> _delay<T>(T Function() body) async {
  await Future<void>.delayed(const Duration(milliseconds: 300));
  return body();
}

class MockApiService implements ApiService {
  @override
  Future<UserInfo> fetchUserInfo(String userId) async {
    return _delay(() {
      if (userId.trim().isEmpty) {
        return const UserInfo(id: 'guest', name: '게스트', email: 'guest@example.com');
      }
      if (userId == '1') {
        return const UserInfo(id: '1', name: '홍길동', email: 'hong@example.com');
      }
      return UserInfo(
        id: userId,
        name: '사용자_' + userId,
        email: userId + '@example.com',
      );
    });
  }
}


