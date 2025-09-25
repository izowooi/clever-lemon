import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sequential_creation_screen.dart';
import 'poetry_list_screen.dart';
import 'settings_screen.dart';
import 'poem_settings_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  int _totalCredits = 0;
  int _freeCredits = 0;
  int _paidCredits = 0;
  bool _isLoadingCredits = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
    _loadUserCredits();
  }

  Future<void> _loadUserCredits() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    setState(() {
      _isLoadingCredits = true;
    });

    try {
      final response = await supabase
          .from('users_credits')
          .select('free_credits, paid_credits')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _freeCredits = response['free_credits'] ?? 0;
          _paidCredits = response['paid_credits'] ?? 0;
          _totalCredits = _freeCredits + _paidCredits;
        });
      }
    } catch (error) {
      print('재화 정보 로딩 오류: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCredits = false;
        });
      }
    }
  }

  void _showCreditsDetail() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Text('✍️ ', style: TextStyle(fontSize: 20)),
              Text('재화 상세 정보'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('무료 재화:', style: TextStyle(fontSize: 16)),
                  Text('$_freeCredits개',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('유료 재화:', style: TextStyle(fontSize: 16)),
                  Text('$_paidCredits개',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('총 재화:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('$_totalCredits개',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
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
        title: const Text(
          'Poetry Writer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _showCreditsDetail,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✍️ ', style: TextStyle(fontSize: 16)),
                  _isLoadingCredits
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          '$_totalCredits',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SequentialCreationScreen(),
          PoetryListScreen(),
          PoemSettingsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          _tabController.animateTo(index);
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.create),
            label: '시 창작',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: '작품 목록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune),
            label: '시 설정',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
