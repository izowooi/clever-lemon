import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../interfaces/auth_adapter.dart';

class FirebaseAnonymousAuthAdapter implements AuthAdapter {
  bool _initialized = false;
  FirebaseAuth? _auth;

  @override
  Future<void> initialize() async {
    try {
      print('[FirebaseAdapter] 초기화 시작 - Firebase.apps.length: ${Firebase.apps.length}');
      
      // 네이티브에서 Firebase가 이미 초기화되었는지 확인
      if (Firebase.apps.isEmpty) {
        print('[FirebaseAdapter] Firebase 앱이 없음 - 네이티브 초기화 대기 중...');
        // 잠시 대기 후 다시 확인
        await Future.delayed(const Duration(milliseconds: 500));
        if (Firebase.apps.isEmpty) {
          print('[FirebaseAdapter] 여전히 Firebase 앱이 없음 - Flutter에서 초기화 시도');
          await Firebase.initializeApp();
          print('[FirebaseAdapter] Firebase.initializeApp() 완료');
        } else {
          print('[FirebaseAdapter] 대기 후 Firebase 앱 발견됨');
        }
      } else {
        print('[FirebaseAdapter] Firebase 앱이 이미 존재함 (네이티브에서 초기화됨) - 기존 앱 사용');
        print('[FirebaseAdapter] 기존 앱 이름: ${Firebase.apps.first.name}');
        print('[FirebaseAdapter] 기존 앱 옵션: ${Firebase.apps.first.options}');
      }
      
      _auth = FirebaseAuth.instance;
      print('[FirebaseAdapter] FirebaseAuth.instance 획득 완료');
      
      // 현재 사용자 상태 확인
      final currentUser = _auth!.currentUser;
      print('[FirebaseAdapter] 현재 사용자: ${currentUser?.uid ?? "없음"}');
      
      _initialized = true;
      print('[FirebaseAdapter] 초기화 성공');
    } catch (e) {
      print('[FirebaseAdapter] 초기화 실패: $e');
      print('[FirebaseAdapter] 에러 타입: ${e.runtimeType}');
      print('[FirebaseAdapter] 스택 트레이스: ${StackTrace.current}');
      _initialized = false;
      rethrow;
    }
  }

  @override
  Future<AuthResult> signIn() async {
    print('[FirebaseAdapter] signIn 호출 - initialized: $_initialized, auth: ${_auth != null}');
    
    if (!_initialized || _auth == null) {
      print('[FirebaseAdapter] signIn 실패 - 초기화되지 않음');
      return AuthResult.failure('Firebase: 초기화 필요');
    }

    try {
      print('[FirebaseAdapter] signInAnonymously 호출 시작');
      final userCredential = await _auth!.signInAnonymously();
      print('[FirebaseAdapter] signInAnonymously 완료');
      
      final user = userCredential.user;
      print('[FirebaseAdapter] 사용자 정보: ${user?.uid}');
      
      if (user != null) {
        final result = AuthResult.success(
          'Firebase: 익명 로그인 성공',
          extra: {
            'uid': user.uid,
            'isAnonymous': user.isAnonymous,
            'creationTime': user.metadata.creationTime?.toIso8601String(),
          },
        );
        print('[FirebaseAdapter] 로그인 성공 - UID: ${user.uid}');
        return result;
      } else {
        print('[FirebaseAdapter] 사용자 정보가 null');
        return AuthResult.failure('Firebase: 사용자 정보를 가져올 수 없음');
      }
    } on FirebaseAuthException catch (e) {
      print('[FirebaseAdapter] FirebaseAuthException: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case "operation-not-allowed":
          message = "Firebase: 익명 인증이 활성화되지 않음";
          break;
        case "network-request-failed":
          message = "Firebase: 네트워크 연결 실패";
          break;
        default:
          message = "Firebase: ${e.message ?? '알 수 없는 오류'}";
      }
      return AuthResult.failure(message);
    } catch (e) {
      print('[FirebaseAdapter] 예상치 못한 오류: $e');
      return AuthResult.failure('Firebase: 예상치 못한 오류 - ${e.toString()}');
    }
  }

  @override
  Future<AuthResult> signOut() async {
    if (!_initialized || _auth == null) {
      return AuthResult.failure('Firebase: 초기화 필요');
    }

    try {
      final currentUser = _auth!.currentUser;
      if (currentUser == null) {
        return AuthResult.failure('Firebase: 로그인되지 않은 상태');
      }

      await _auth!.signOut();
      return AuthResult.success('Firebase: 로그아웃 성공');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure('Firebase: 로그아웃 실패 - ${e.message}');
    } catch (e) {
      return AuthResult.failure('Firebase: 로그아웃 중 오류 - ${e.toString()}');
    }
  }

  /// 현재 사용자 정보를 가져오는 추가 메서드
  Future<AuthResult> getCurrentUser() async {
    if (!_initialized || _auth == null) {
      return AuthResult.failure('Firebase: 초기화 필요');
    }

    try {
      final user = _auth!.currentUser;
      if (user != null) {
        return AuthResult.success(
          'Firebase: 현재 사용자 정보',
          extra: {
            'uid': user.uid,
            'isAnonymous': user.isAnonymous,
            'email': user.email,
            'displayName': user.displayName,
            'creationTime': user.metadata.creationTime?.toIso8601String(),
            'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
          },
        );
      } else {
        return AuthResult.failure('Firebase: 로그인된 사용자 없음');
      }
    } catch (e) {
      return AuthResult.failure('Firebase: 사용자 정보 조회 실패 - ${e.toString()}');
    }
  }

  /// 익명 계정 삭제 메서드
  Future<AuthResult> deleteAccount() async {
    if (!_initialized || _auth == null) {
      return AuthResult.failure('Firebase: 초기화 필요');
    }

    try {
      final user = _auth!.currentUser;
      if (user == null) {
        return AuthResult.failure('Firebase: 로그인된 사용자 없음');
      }

      await user.delete();
      return AuthResult.success('Firebase: 계정 삭제 성공');
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case "requires-recent-login":
          message = "Firebase: 최근 로그인이 필요함";
          break;
        default:
          message = "Firebase: 계정 삭제 실패 - ${e.message}";
      }
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('Firebase: 계정 삭제 중 오류 - ${e.toString()}');
    }
  }
}
