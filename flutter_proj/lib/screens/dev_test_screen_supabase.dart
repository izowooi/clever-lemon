import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart' as main;

class SupabaseTestHarness extends ConsumerStatefulWidget {
  const SupabaseTestHarness({super.key});

  @override
  ConsumerState<SupabaseTestHarness> createState() => _SupabaseTestHarnessState();
}

class _SupabaseTestHarnessState extends ConsumerState<SupabaseTestHarness> {
  String _log = '';
  bool _working = false;
  
  // 테스트할 사용자 ID (수정 가능)
  String _testUserId = '13McgMNHlYckeTudiqAbr1lNYQo2';
  final TextEditingController _userIdController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _userIdController.text = _testUserId;
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _testSelectCredits() async {
    _working = true;
    _log = '크레딧 조회 중... (user_id: $_testUserId)';
    print('[Supabase] 크레딧 조회 시작 - user_id: $_testUserId');
    setState(() {});

    try {
      final response = await main.supabase
          .from('user_credits')
          .select('credits, updated_at')
          .eq('user_id', _testUserId)
          .maybeSingle();

      if (response != null) {
        _log = '크레딧 조회 성공!\n\n';
        _log += 'user_id: $_testUserId\n';
        _log += 'credits: ${response['credits']}\n';
        _log += 'updated_at: ${response['updated_at']}\n';
        print('[Supabase] 크레딧 조회 성공: ${response['credits']}');
      } else {
        _log = '크레딧 조회 결과: 해당 사용자의 레코드가 없습니다.\n\n';
        _log += 'user_id: $_testUserId\n';
        _log += '상태: 레코드 없음';
        print('[Supabase] 레코드 없음');
      }
    } catch (e) {
      _log = '크레딧 조회 실패!\n\n';
      _log += 'user_id: $_testUserId\n';
      _log += 'Error: ${e.toString()}';
      print('[Supabase] 크레딧 조회 실패: $e');
    } finally {
      _working = false;
      setState(() {});
    }
  }

  Future<void> _testInsertCredits() async {
    _working = true;
    _log = '크레딧 생성 중... (user_id: $_testUserId)';
    print('[Supabase] 크레딧 생성 시작 - user_id: $_testUserId');
    setState(() {});

    try {
      final response = await main.supabase
          .from('user_credits')
          .insert({
            'user_id': _testUserId,
            'credits': 500,
          })
          .select()
          .single();

      _log = '크레딧 생성 성공!\n\n';
      _log += 'user_id: ${response['user_id']}\n';
      _log += 'credits: ${response['credits']}\n';
      _log += 'updated_at: ${response['updated_at']}\n';
      print('[Supabase] 크레딧 생성 성공');
    } catch (e) {
      _log = '크레딧 생성 실패!\n\n';
      _log += 'user_id: $_testUserId\n';
      _log += 'Error: ${e.toString()}\n\n';
      
      if (e.toString().contains('duplicate key')) {
        _log += '참고: 이미 해당 사용자의 레코드가 존재합니다.';
      }
      print('[Supabase] 크레딧 생성 실패: $e');
    } finally {
      _working = false;
      setState(() {});
    }
  }

  Future<void> _testUpsertCredits() async {
    _working = true;
    _log = '크레딧 업서트 중... (user_id: $_testUserId)';
    print('[Supabase] 크레딧 업서트 시작 - user_id: $_testUserId');
    setState(() {});

    try {
      final response = await main.supabase
          .from('user_credits')
          .upsert({
            'user_id': _testUserId,
            'credits': 750,
          })
          .select()
          .single();

      _log = '크레딧 업서트 성공!\n\n';
      _log += 'user_id: ${response['user_id']}\n';
      _log += 'credits: ${response['credits']}\n';
      _log += 'updated_at: ${response['updated_at']}\n';
      _log += '\n참고: 레코드가 없으면 생성, 있으면 업데이트됩니다.';
      print('[Supabase] 크레딧 업서트 성공');
    } catch (e) {
      _log = '크레딧 업서트 실패!\n\n';
      _log += 'user_id: $_testUserId\n';
      _log += 'Error: ${e.toString()}';
      print('[Supabase] 크레딧 업서트 실패: $e');
    } finally {
      _working = false;
      setState(() {});
    }
  }

  Future<void> _testUpdateCredits() async {
    _working = true;
    _log = '크레딧 업데이트 중... (user_id: $_testUserId)';
    print('[Supabase] 크레딧 업데이트 시작 - user_id: $_testUserId');
    setState(() {});

    try {
      final response = await main.supabase
          .from('user_credits')
          .update({'credits': 1000})
          .eq('user_id', _testUserId)
          .select()
          .single();

      _log = '크레딧 업데이트 성공!\n\n';
      _log += 'user_id: ${response['user_id']}\n';
      _log += 'credits: ${response['credits']}\n';
      _log += 'updated_at: ${response['updated_at']}\n';
      print('[Supabase] 크레딧 업데이트 성공');
    } catch (e) {
      _log = '크레딧 업데이트 실패!\n\n';
      _log += 'user_id: $_testUserId\n';
      _log += 'Error: ${e.toString()}\n\n';
      
      if (e.toString().contains('No rows found')) {
        _log += '참고: 해당 사용자의 레코드가 존재하지 않습니다.';
      }
      print('[Supabase] 크레딧 업데이트 실패: $e');
    } finally {
      _working = false;
      setState(() {});
    }
  }

  Future<void> _testDeleteCredits() async {
    _working = true;
    _log = '크레딧 삭제 중... (user_id: $_testUserId)';
    print('[Supabase] 크레딧 삭제 시작 - user_id: $_testUserId');
    setState(() {});

    try {
      await main.supabase
          .from('user_credits')
          .delete()
          .eq('user_id', _testUserId);

      _log = '크레딧 삭제 성공!\n\n';
      _log += 'user_id: $_testUserId\n';
      _log += '상태: 레코드가 삭제되었습니다.';
      print('[Supabase] 크레딧 삭제 성공');
    } catch (e) {
      _log = '크레딧 삭제 실패!\n\n';
      _log += 'user_id: $_testUserId\n';
      _log += 'Error: ${e.toString()}';
      print('[Supabase] 크레딧 삭제 실패: $e');
    } finally {
      _working = false;
      setState(() {});
    }
  }

  Future<void> _testListAllCredits() async {
    _working = true;
    _log = '전체 크레딧 목록 조회 중...';
    print('[Supabase] 전체 크레딧 목록 조회 시작');
    setState(() {});

    try {
      final response = await main.supabase
          .from('user_credits')
          .select('user_id, credits, updated_at')
          .order('updated_at', ascending: false)
          .limit(10);

      _log = '전체 크레딧 목록 조회 성공!\n\n';
      _log += '총 ${response.length}개 레코드:\n\n';
      
      for (int i = 0; i < response.length; i++) {
        final record = response[i];
        _log += '${i + 1}. user_id: ${record['user_id']}\n';
        _log += '   credits: ${record['credits']}\n';
        _log += '   updated_at: ${record['updated_at']}\n\n';
      }
      
      if (response.isEmpty) {
        _log += '레코드가 없습니다.';
      }
      
      print('[Supabase] 전체 크레딧 목록 조회 성공: ${response.length}개');
    } catch (e) {
      _log = '전체 크레딧 목록 조회 실패!\n\n';
      _log += 'Error: ${e.toString()}';
      print('[Supabase] 전체 크레딧 목록 조회 실패: $e');
    } finally {
      _working = false;
      setState(() {});
    }
  }

  void _updateUserId() {
    setState(() {
      _testUserId = _userIdController.text.trim();
    });
    print('[Supabase] 테스트 사용자 ID 변경: $_testUserId');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supabase DB 테스트',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'user_credits 테이블 CRUD 테스트\nRLS 정책으로 사용자별 접근 제어 확인',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          
          // 사용자 ID 입력 필드
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: '테스트 사용자 ID',
                    hintText: '13McgMNHlYckeTudiqAbr1lNYQo2',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _updateUserId(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _updateUserId,
                child: const Text('적용'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 테스트 버튼들
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _working ? null : _testSelectCredits,
                icon: const Icon(Icons.search),
                label: const Text('조회'),
              ),
              ElevatedButton.icon(
                onPressed: _working ? null : _testInsertCredits,
                icon: const Icon(Icons.add),
                label: const Text('생성'),
              ),
              ElevatedButton.icon(
                onPressed: _working ? null : _testUpsertCredits,
                icon: const Icon(Icons.sync),
                label: const Text('업서트'),
              ),
              ElevatedButton.icon(
                onPressed: _working ? null : _testUpdateCredits,
                icon: const Icon(Icons.edit),
                label: const Text('업데이트'),
              ),
              ElevatedButton.icon(
                onPressed: _working ? null : _testDeleteCredits,
                icon: const Icon(Icons.delete),
                label: const Text('삭제'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade800,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _working ? null : _testListAllCredits,
                icon: const Icon(Icons.list),
                label: const Text('전체 목록'),
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
  }
}
