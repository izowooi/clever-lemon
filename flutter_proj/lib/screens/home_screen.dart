import 'package:flutter/material.dart';
import 'package:flutter_proj/screens/auth_test_screen.dart';
import 'sequential_creation_screen.dart';
import 'daily_quote_list_screen.dart';
import 'settings_screen.dart';
import 'dev_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
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
          '오늘의 글귀',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        centerTitle: true,
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SequentialCreationScreen(),
          DailyQuoteListScreen(),
          SettingsScreen(),
          DevTestScreen(),
          //AuthTestScreen(),
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
            label: '글귀 창작',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_quote),
            label: '글귀 모음',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.developer_board),
            label: '개발 테스트',
          ),
        ],
      ),
    );
  }
}
