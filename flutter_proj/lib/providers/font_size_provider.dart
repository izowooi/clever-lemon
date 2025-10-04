import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSizeOption {
  small('작게', 1.0),
  medium('보통', 1.5),
  large('크게', 2.0),
  extraLarge('아주 크게', 3.0);

  final String label;
  final double scale;

  const FontSizeOption(this.label, this.scale);

  static FontSizeOption fromLabel(String label) {
    return FontSizeOption.values.firstWhere(
      (option) => option.label == label,
      orElse: () => FontSizeOption.small,
    );
  }
}

class FontSizeNotifier extends StateNotifier<FontSizeOption> {
  static const String _fontSizeKey = 'font_size_option';

  FontSizeNotifier() : super(FontSizeOption.small) {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLabel = prefs.getString(_fontSizeKey);
      if (savedLabel != null) {
        state = FontSizeOption.fromLabel(savedLabel);
      }
    } catch (e) {
      // ignore: avoid_print
      print('폰트 크기 설정 로드 실패: $e');
    }
  }

  Future<void> setFontSize(FontSizeOption option) async {
    state = option;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fontSizeKey, option.label);
    } catch (e) {
      // ignore: avoid_print
      print('폰트 크기 설정 저장 실패: $e');
    }
  }
}

final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, FontSizeOption>((ref) {
  return FontSizeNotifier();
});
