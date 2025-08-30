import '../../models/user_info.dart';

abstract class ApiService {
  Future<UserInfo> fetchUserInfo(String userId);
}


