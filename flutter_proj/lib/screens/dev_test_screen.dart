import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/interfaces/auth_adapter.dart';
import '../services/implementations/mock_auth_adapters.dart';



import 'dev_test_screen_remote_config.dart';
import 'dev_test_screen_supabase.dart';

final _googleAuthProvider = Provider<AuthAdapter>((ref) => GoogleAuthAdapter());
final _appleAuthProvider = Provider<AuthAdapter>((ref) => AppleAuthAdapter());
final _guestAuthProvider = Provider<AuthAdapter>((ref) => GuestAuthAdapter());




class DevTestScreen extends ConsumerStatefulWidget {
  const DevTestScreen({super.key});

  @override
  ConsumerState<DevTestScreen> createState() => _DevTestScreenState();
}

class _DevTestScreenState extends ConsumerState<DevTestScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('개발 테스트 허브'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Auth'),
            Tab(text: 'Remote'),
            Tab(text: 'Messaging'),
            Tab(text: 'Supabase'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AuthTab(),
          RemoteConfigTestHarness(),
          _PlaceholderTab(title: 'Messaging'),
          SupabaseTestHarness(),
        ],
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  const _AuthTab();

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Google'),
              Tab(text: 'Apple'),
              Tab(text: 'Guest'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _AuthHarness(providerKey: _AuthProviderKey.google),
                _AuthHarness(providerKey: _AuthProviderKey.apple),
                _AuthHarness(providerKey: _AuthProviderKey.guest),
              ],
            ),
          ),
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

  AuthAdapter _readAdapter(WidgetRef ref) {
    switch (widget.providerKey) {
      case _AuthProviderKey.google:
        return ref.read(_googleAuthProvider);
      case _AuthProviderKey.apple:
        return ref.read(_appleAuthProvider);
      case _AuthProviderKey.guest:
        return ref.read(_guestAuthProvider);
    }
  }

  Future<void> _initialize(WidgetRef ref) async {
    _initializing = true;
    _log = '초기화 중...';
    setState(() {});
    final adapter = _readAdapter(ref);
    try {
      await adapter.initialize();
      _log = '초기화 완료';
    } catch (e) {
      _log = '초기화 실패: ' + e.toString();
    } finally {
      _initializing = false;
      setState(() {});
    }
  }

  Future<void> _signIn(WidgetRef ref) async {
    _working = true;
    _log = '로그인 중...';
    setState(() {});
    final adapter = _readAdapter(ref);
    final result = await adapter.signIn();
    _log = (result.isSuccess ? '성공: ' : '실패: ') + result.message + (result.extra != null ? '\n' + result.extra.toString() : '');
    _working = false;
    setState(() {});
  }

  Future<void> _signOut(WidgetRef ref) async {
    _working = true;
    _log = '로그아웃 중...';
    setState(() {});
    final adapter = _readAdapter(ref);
    final result = await adapter.signOut();
    _log = (result.isSuccess ? '성공: ' : '실패: ') + result.message;
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
                    label: const Text('로그인'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _initializing || _working ? null : () => _signOut(ref),
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
      },
    );
  }
}


class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});
  
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "곧 구현될 예정입니다",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
