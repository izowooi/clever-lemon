import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generic_creation_screen.dart';
import 'settings_screen.dart';
import '../providers/user_credits_provider.dart';
import '../providers/generic_creation_provider.dart';
import '../widgets/poetry_list_popup.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  void _showCreditsDetail() {
    final creditsState = ref.read(userCreditsProvider);

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
                  Text('${creditsState.freeCredits}개',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('유료 재화:', style: TextStyle(fontSize: 16)),
                  Text('${creditsState.paidCredits}개',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('총 재화:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${creditsState.totalCredits}개',
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

  void _showPoetryListPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const PoetryListPopup();
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
    final creditsState = ref.watch(userCreditsProvider);

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
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
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
                  creditsState.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          '${creditsState.totalCredits}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _showPoetryListPopup,
            icon: const Icon(Icons.library_books),
            tooltip: '작품 목록',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          GenericCreationScreen(
            creationType: CreationType.poetry,
          ),
          GenericCreationScreen(
            creationType: CreationType.dailyVerse,
          ),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _tabController.animateTo(index);
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.create),
            label: '시 창작',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories),
            label: '오늘의 글귀',
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
