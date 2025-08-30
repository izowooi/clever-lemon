import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/interfaces/auth_adapter.dart';
import '../services/implementations/mock_auth_adapters.dart';

final _googleAuthProvider = Provider<AuthAdapter>((ref) => GoogleAuthAdapter());
final _appleAuthProvider = Provider<AuthAdapter>((ref) => AppleAuthAdapter());
final _guestAuthProvider = Provider<AuthAdapter>((ref) => GuestAuthAdapter());

class AuthTestScreen extends ConsumerStatefulWidget {
  const AuthTestScreen({super.key});

  @override
  ConsumerState<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends ConsumerState<AuthTestScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth 테스트'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Google'),
            Tab(text: 'Apple'),
            Tab(text: 'Guest'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AuthHarness(providerKey: _AuthProviderKey.google),
          _AuthHarness(providerKey: _AuthProviderKey.apple),
          _AuthHarness(providerKey: _AuthProviderKey.guest),
        ],
      ),
    );
  }
}

enum _AuthProviderKey { google, apple, guest }

class _AuthHarness extends ConsumerStatefulWidget {
  const _AuthHarness({required this.providerKey});

  final _AuthProviderKey providerKey;

  @override
  ConsumerState<_AuthHarness> createState() => _AuthHarnessState();
}

class _AuthHarnessState extends ConsumerState<_AuthHarness> {
  String _log = '';
  bool _initializing = false;
  bool _working = false;

  AuthAdapter _readAdapter() {
    switch (widget.providerKey) {
      case _AuthProviderKey.google:
        return ref.read(_googleAuthProvider);
      case _AuthProviderKey.apple:
        return ref.read(_appleAuthProvider);
      case _AuthProviderKey.guest:
        return ref.read(_guestAuthProvider);
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _initializing = true;
      _log = '초기화 중...';
    });
    final adapter = _readAdapter();
    try {
      await adapter.initialize();
      setState(() {
        _log = '초기화 완료';
      });
    } catch (e) {
      setState(() {
        _log = '초기화 실패: ' + e.toString();
      });
    } finally {
      setState(() {
        _initializing = false;
      });
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _working = true;
      _log = '로그인 중...';
    });
    final adapter = _readAdapter();
    final result = await adapter.signIn();
    setState(() {
      _log = (result.isSuccess ? '성공: ' : '실패: ') + result.message + (result.extra != null ? '\n' + result.extra.toString() : '');
      _working = false;
    });
  }

  Future<void> _signOut() async {
    setState(() {
      _working = true;
      _log = '로그아웃 중...';
    });
    final adapter = _readAdapter();
    final result = await adapter.signOut();
    setState(() {
      _log = (result.isSuccess ? '성공: ' : '실패: ') + result.message;
      _working = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: _initializing || _working ? null : _initialize,
                icon: const Icon(Icons.power_settings_new),
                label: const Text('초기화'),
              ),
              ElevatedButton.icon(
                onPressed: _initializing || _working ? null : _signIn,
                icon: const Icon(Icons.login),
                label: const Text('로그인'),
              ),
              ElevatedButton.icon(
                onPressed: _initializing || _working ? null : _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
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
                child: Text(
                  _log,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


