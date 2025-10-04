import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeColorOption {
  deepPurple('보라', Colors.deepPurple),
  indigo('남색', Colors.indigo),
  blue('파랑', Colors.blue),
  teal('청록', Colors.teal),
  green('초록', Colors.green),
  amber('호박', Colors.amber),
  deepOrange('주황', Colors.deepOrange),
  pink('분홍', Colors.pink),
  blueGrey('회청', Colors.blueGrey),
  brown('갈색', Colors.brown);

  final String label;
  final Color color;

  const ThemeColorOption(this.label, this.color);

  static ThemeColorOption fromLabel(String label) {
    return ThemeColorOption.values.firstWhere(
      (option) => option.label == label,
      orElse: () => ThemeColorOption.deepPurple,
    );
  }
}

class ThemeColorNotifier extends StateNotifier<ThemeColorOption> {
  static const String _themeColorKey = 'theme_color_option';

  ThemeColorNotifier() : super(ThemeColorOption.deepPurple) {
    _loadThemeColor();
  }

  Future<void> _loadThemeColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLabel = prefs.getString(_themeColorKey);
      if (savedLabel != null) {
        state = ThemeColorOption.fromLabel(savedLabel);
      }
    } catch (e) {
      // ignore: avoid_print
      print('테마 색상 설정 로드 실패: $e');
    }
  }

  Future<void> setThemeColor(ThemeColorOption option) async {
    state = option;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeColorKey, option.label);
    } catch (e) {
      // ignore: avoid_print
      print('테마 색상 설정 저장 실패: $e');
    }
  }
}

final themeColorProvider = StateNotifierProvider<ThemeColorNotifier, ThemeColorOption>((ref) {
  return ThemeColorNotifier();
});
