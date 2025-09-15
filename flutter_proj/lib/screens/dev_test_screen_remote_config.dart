import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/remote_config_service.dart';

final _remoteConfigProvider = Provider<RemoteConfigService>((ref) => RemoteConfigService.instance);

class RemoteConfigTestHarness extends ConsumerStatefulWidget {
  const RemoteConfigTestHarness({super.key});

  @override
  ConsumerState<RemoteConfigTestHarness> createState() => _RemoteConfigTestHarnessState();
}

class _RemoteConfigTestHarnessState extends ConsumerState<RemoteConfigTestHarness> {
  String _log = '';
  bool _initializing = false;
  bool _working = false;

  // 기본값 설정
  final Map<String, Object> _defaultValues = {
    'review_versioncode_aos': 1,
    'review_versioncode_ios': 1,
    'api_base_url': 'https://clever-lemon.zowoo.uk',
  };

  Future<void> _initialize(WidgetRef ref) async {
    _initializing = true;
    _log = 'Remote Config 초기화 중...';
    print('[RemoteConfig] 초기화 시작');
    setState(() {});

    final service = ref.read(_remoteConfigProvider);
    try {
      await service.initialize();
      _log = 'Remote Config 초기화 완료';
      print('[RemoteConfig] 초기화 완료');
    } catch (e) {
      _log = 'Remote Config 초기화 실패: ' + e.toString();
      print('[RemoteConfig] 초기화 실패: $e');
    } finally {
      _initializing = false;
      setState(() {});
    }
  }

  Future<void> _setDefaults(WidgetRef ref) async {
    _working = true;
    _log = '기본값 설정 중...';
    print('[RemoteConfig] 기본값 설정 시작');
    setState(() {});
    
    final service = ref.read(_remoteConfigProvider);
    try {
      await service.setDefaults(_defaultValues);
      _log = '기본값 설정 완료\n' + _defaultValues.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      print('[RemoteConfig] 기본값 설정 완료');
    } catch (e) {
      _log = '기본값 설정 실패: ' + e.toString();
      print('[RemoteConfig] 기본값 설정 실패: $e');
    } finally {
      _working = false;
      setState(() {});
    }
  }

  Future<void> _fetchAndActivate(WidgetRef ref) async {
    _working = true;
    _log = 'Fetch + Activate 중...';
    print('[RemoteConfig] Fetch + Activate 시작');
    setState(() {});
    
    final service = ref.read(_remoteConfigProvider);
    final success = await service.fetchAndActivate();
    _log = success ? '성공: Fetch + Activate 완료' : '실패: Fetch + Activate 실패';

    if (success) {
      _log += '\n\n현재 값들:\n';
      _log += 'review_versioncode_aos: ${service.getReviewVersionAos()}\n';
      _log += 'review_versioncode_ios: ${service.getReviewVersionIos()}\n';
      _log += 'api_base_url: ${service.getApiBaseUrl()}\n';
      _log += 'poem_settings_config: ${service.getPoemSettingsConfig()}\n';
    }

    print('[RemoteConfig] Fetch + Activate 결과: ${success ? "성공" : "실패"}');
    
    _working = false;
    setState(() {});
  }

  Future<void> _getCurrentValues(WidgetRef ref) async {
    _working = true;
    _log = '현재 값 조회 중...';
    print('[RemoteConfig] 현재 값 조회 시작');
    setState(() {});
    
    final service = ref.read(_remoteConfigProvider);
    
    try {
      final reviewVersionAos = service.getInt('review_versioncode_aos');
      final reviewVersionIos = service.getInt('review_versioncode_ios');
      final apiBaseUrl = service.getString('api_base_url');
      
      _log = '현재 Remote Config 값들:\n\n';
      _log += 'review_versioncode_aos: $reviewVersionAos\n';
      _log += 'review_versioncode_ios: $reviewVersionIos\n';
      _log += 'api_base_url: $apiBaseUrl\n';
      
      print('[RemoteConfig] 현재 값들 조회 완료');
      print('[RemoteConfig] review_versioncode_aos: $reviewVersionAos');
      print('[RemoteConfig] review_versioncode_ios: $reviewVersionIos');
      print('[RemoteConfig] api_base_url: $apiBaseUrl');
    } catch (e) {
      _log = '현재 값 조회 실패: ' + e.toString();
      print('[RemoteConfig] 현재 값 조회 실패: $e');
    } finally {
      _working = false;
      setState(() {});
    }
  }

  Future<void> _getConfigInfo(WidgetRef ref) async {
    _working = true;
    _log = 'Config 정보 조회 중...';
    print('[RemoteConfig] Config 정보 조회 시작');
    setState(() {});
    
    final service = ref.read(_remoteConfigProvider);
    final configInfo = service.getConfigInfo();
    
    if (configInfo != null) {
      _log = '성공: Config 정보 조회 완료';
      _log += '\n\nConfig 정보:\n';
      configInfo.forEach((key, value) {
        if (value is Map) {
          _log += '$key:\n';
          value.forEach((k, v) => _log += '  $k: $v\n');
        } else {
          _log += '$key: $value\n';
        }
      });
      print('[RemoteConfig] Config 정보 결과: 성공');
    } else {
      _log = '실패: Config 정보 조회 실패';
      print('[RemoteConfig] Config 정보 결과: 실패');
    }
    
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
              Text(
                'Remote Config 테스트',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '테스트할 키값들:\n• review_versioncode_aos (int)\n• review_versioncode_ios (int)\n• api_base_url (string)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
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
                    onPressed: _initializing || _working ? null : () => _setDefaults(ref),
                    icon: const Icon(Icons.settings),
                    label: const Text('기본값 설정'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _initializing || _working ? null : () => _fetchAndActivate(ref),
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Fetch+Activate'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _initializing || _working ? null : () => _getCurrentValues(ref),
                    icon: const Icon(Icons.visibility),
                    label: const Text('현재 값 조회'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _initializing || _working ? null : () => _getConfigInfo(ref),
                    icon: const Icon(Icons.info),
                    label: const Text('Config 정보'),
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
