import 'package:flutter/material.dart';

class DailyQuoteListScreen extends StatelessWidget {
  const DailyQuoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.format_quote,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '글귀 모음',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '곧 구현될 예정입니다',
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
