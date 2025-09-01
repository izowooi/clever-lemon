import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/implementations/firebase_auth_adapter.dart';

final _firebaseAuthProvider = Provider<FirebaseAnonymousAuthAdapter>((ref) => FirebaseAnonymousAuthAdapter());

class FirebaseAuthHarness extends ConsumerStatefulWidget {
  const FirebaseAuthHarness({super.key});

  @override
  ConsumerState<FirebaseAuthHarness> createState() => _FirebaseAuthHarnessState();
}

class _FirebaseAuthHarnessState extends ConsumerState<FirebaseAuthHarness> {
  String _log = '';
  bool _initializing = false;
  bool _working = false;

  Future<void> _initialize(WidgetRef ref) async {
    _initializing = true;
    _log = 'Firebase 초기화 중...';
    print('[Firebase] 초기화 시작');
    setState(() {});
    final adapter = ref.read(_firebaseAuthProvider);
    try {
      await adapter.initialize();
      _log = 'Firebase 초기화 완료';
      print('[Firebase] 초기화 완료');
    } catch (e) {
      _log = 'Firebase 초기화 실패: ' + e.toString();
      print('[Firebase] 초기화 실패: $e');
    } finally {
      _initializing = false;
      setState(() {});
    }
  }

  Future<void> _signIn(WidgetRef ref) async {
    _working = true;
    _log = 'Firebase 익명 로그인 중...';
    print('[Firebase] 익명 로그인 시작');
    setState(() {});
    final adapter = ref.read(_firebaseAuthProvider);
    final result = await adapter.signIn();
    _log = (result.isSuccess ? '성공: ' : '실패: ') + result.message + (result.extra != null ? '\n' + result.extra.toString() : '');
    print('[Firebase] 로그인 결과: ${result.isSuccess ? "성공" : "실패"} - ${result.message}');
    if (result.extra != null) {
      print('[Firebase] 추가 정보: ${result.extra}');
    }
    _working = false;
    setState(() {});
  }

  Future<void> _signOut(WidgetRef ref) async {
    _working = true;
    _log = 'Firebase 로그아웃 중...';
    print('[Firebase] 로그아웃 시작');
    setState(() {});
    final adapter = ref.read(_firebaseAuthProvider);
    final result = await adapter.signOut();
    _log = (result.isSuccess ? '성공: ' : '실패: ') + result.message;
    print('[Firebase] 로그아웃 결과: ${result.isSuccess ? "성공" : "실패"} - ${result.message}');
    _working = false;
    setState(() {});
  }

  Future<void> _getCurrentUser(WidgetRef ref) async {
    _working = true;
    _log = '사용자 정보 조회 중...';
    print('[Firebase] 사용자 정보 조회 시작');
    setState(() {});
    final adapter = ref.read(_firebaseAuthProvider);
    final result = await adapter.getCurrentUser();
    _log = (result.isSuccess ? '성공: ' : '실패: ') + result.message + (result.extra != null ? '\n' + result.extra.toString() : '');
    print('[Firebase] 사용자 정보 결과: ${result.isSuccess ? "성공" : "실패"} - ${result.message}');
    if (result.extra != null) {
      print('[Firebase] 사용자 정보: ${result.extra}');
    }
    _working = false;
    setState(() {});
  }

  Future<void> _deleteAccount(WidgetRef ref) async {
    _working = true;
    _log = '계정 삭제 중...';
    print('[Firebase] 계정 삭제 시작');
    setState(() {});
    final adapter = ref.read(_firebaseAuthProvider);
    final result = await adapter.deleteAccount();
    _log = (result.isSuccess ? '성공: ' : '실패: ') + result.message;
    print('[Firebase] 계정 삭제 결과: ${result.isSuccess ? "성공" : "실패"} - ${result.message}');
    _working = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _initializing || _working ? null : () => _initialize(ref),
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('초기화'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _initializing || _working ? null : () => _signIn(ref),
                    icon: const Icon(Icons.login),
                    label: const Text('익명 로그인'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _initializing || _working ? null : () => _signOut(ref),
                    icon: const Icon(Icons.logout),
                    label: const Text('로그아웃'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _initializing || _working ? null : () => _getCurrentUser(ref),
                    icon: const Icon(Icons.person),
                    label: const Text('사용자 정보'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _initializing || _working ? null : () => _deleteAccount(ref),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('계정 삭제'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '로그',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _log,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
