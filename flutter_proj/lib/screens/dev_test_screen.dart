import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/interfaces/auth_adapter.dart';
import '../services/implementations/mock_auth_adapters.dart';
import '../services/interfaces/remote_config_adapter.dart';
import '../services/implementations/mock_remote_config_adapter.dart';
import '../services/implementations/mock_messaging_adapter.dart';
import '../services/interfaces/api_service.dart';
import '../services/implementations/mock_api_service.dart';

final _googleAuthProvider = Provider<AuthAdapter>((ref) => GoogleAuthAdapter());
final _appleAuthProvider = Provider<AuthAdapter>((ref) => AppleAuthAdapter());
final _guestAuthProvider = Provider<AuthAdapter>((ref) => GuestAuthAdapter());

final _remoteConfigProvider = Provider<RemoteConfigAdapter>((ref) => MockRemoteConfigAdapter());
final _messagingProvider = Provider<MockMessagingAdapter>((ref) => MockMessagingAdapter());
final _apiProvider = Provider<ApiService>((ref) => MockApiService());

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
            Tab(text: 'API'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AuthTab(),
          _RemoteConfigTab(),
          _MessagingTab(),
          _ApiTab(),
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

class _RemoteConfigTab extends ConsumerStatefulWidget {
  const _RemoteConfigTab();

  @override
  ConsumerState<_RemoteConfigTab> createState() => _RemoteConfigTabState();
}

class _RemoteConfigTabState extends ConsumerState<_RemoteConfigTab> {
  String _log = '';
  bool _initializing = false;
  bool _working = false;

  Future<void> _initialize(WidgetRef ref) async {
    _initializing = true;
    _log = '초기화 중...';
    setState(() {});
    final rc = ref.read(_remoteConfigProvider);
    try {
      await rc.initialize();
      await rc.setDefaults({
        'welcome_message': '기본 메시지',
        'feature_enabled': false,
        'max_items': 10,
        'pi_value': 3.0,
      });
      _log = '초기화 + 기본값 설정 완료';
    } catch (e) {
      _log = '초기화 실패: ' + e.toString();
    } finally {
      _initializing = false;
      setState(() {});
    }
  }

  Future<void> _fetchAndActivate(WidgetRef ref) async {
    _working = true;
    _log = 'Fetch + Activate 중...';
    setState(() {});
    final rc = ref.read(_remoteConfigProvider);
    final result = await rc.fetchAndActivate();
    _log = (result.isSuccess ? '성공: ' : '실패: ') + result.message + '\n' +
        'welcome_message=' + rc.getString('welcome_message') + '\n' +
        'feature_enabled=' + rc.getBool('feature_enabled').toString() + '\n' +
        'max_items=' + rc.getInt('max_items').toString() + '\n' +
        'pi_value=' + rc.getDouble('pi_value').toString();
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
                    onPressed: _initializing || _working ? null : () => _fetchAndActivate(ref),
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Fetch+Activate'),
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

class _MessagingTab extends ConsumerStatefulWidget {
  const _MessagingTab();

  @override
  ConsumerState<_MessagingTab> createState() => _MessagingTabState();
}

class _MessagingTabState extends ConsumerState<_MessagingTab> {
  String _log = '';
  String _topic = '';
  bool _initializing = false;
  bool _working = false;

  Future<void> _initialize(WidgetRef ref) async {
    _initializing = true;
    _log = '초기화 중...';
    setState(() {});
    final m = ref.read(_messagingProvider);
    try {
      await m.initialize();
      _log = '초기화 완료';
    } catch (e) {
      _log = '초기화 실패: ' + e.toString();
    } finally {
      _initializing = false;
      setState(() {});
    }
  }

  Future<void> _subscribe(WidgetRef ref) async {
    _working = true;
    _log = '구독 중...';
    setState(() {});
    final m = ref.read(_messagingProvider);
    final result = await m.subscribeToTopic(_topic);
    _log = (result.isSuccess ? '성공: ' : '실패: ') + result.message + '\n' +
        '현재 토픽: ' + m.topics.join(', ');
    _working = false;
    setState(() {});
  }

  Future<void> _unsubscribe(WidgetRef ref) async {
    _working = true;
    _log = '구독 해제 중...';
    setState(() {});
    final m = ref.read(_messagingProvider);
    final result = await m.unsubscribeFromTopic(_topic);
    _log = (result.isSuccess ? '성공: ' : '실패: ') + result.message + '\n' +
        '현재 토픽: ' + m.topics.join(', ');
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
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: '토픽',
                        hintText: '예: news, all-users',
                      ),
                      onChanged: (v) => _topic = v,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _initializing || _working ? null : () => _initialize(ref),
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('초기화'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _initializing || _working ? null : () => _subscribe(ref),
                    icon: const Icon(Icons.add_alert),
                    label: const Text('구독'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _initializing || _working ? null : () => _unsubscribe(ref),
                    icon: const Icon(Icons.notifications_off),
                    label: const Text('구독 해제'),
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

class _ApiTab extends ConsumerStatefulWidget {
  const _ApiTab();

  @override
  ConsumerState<_ApiTab> createState() => _ApiTabState();
}

class _ApiTabState extends ConsumerState<_ApiTab> {
  String _log = '';
  String _userId = '';
  bool _working = false;

  Future<void> _fetch(WidgetRef ref) async {
    _working = true;
    _log = '요청 중...';
    setState(() {});
    final api = ref.read(_apiProvider);
    final info = await api.fetchUserInfo(_userId);
    _log = '응답 수신:\n' + info.toString();
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
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: '유저 ID',
                        hintText: '예: 1, 2, abc',
                      ),
                      onChanged: (v) => _userId = v,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _working ? null : () => _fetch(ref),
                    icon: const Icon(Icons.send),
                    label: const Text('조회'),
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


