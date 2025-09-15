class PoemSettings {
  final String style;
  final String authorStyle;
  final int length;

  const PoemSettings({
    required this.style,
    required this.authorStyle,
    required this.length,
  });

  PoemSettings copyWith({
    String? style,
    String? authorStyle,
    int? length,
  }) {
    return PoemSettings(
      style: style ?? this.style,
      authorStyle: authorStyle ?? this.authorStyle,
      length: length ?? this.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'style': style,
      'authorStyle': authorStyle,
      'length': length,
    };
  }

  factory PoemSettings.fromJson(Map<String, dynamic> json) {
    return PoemSettings(
      style: json['style'] as String,
      authorStyle: json['authorStyle'] as String,
      length: json['length'] as int,
    );
  }

  static const PoemSettings defaultSettings = PoemSettings(
    style: '낭만적인',
    authorStyle: '김소월',
    length: 4,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PoemSettings &&
        other.style == style &&
        other.authorStyle == authorStyle &&
        other.length == length;
  }

  @override
  int get hashCode => Object.hash(style, authorStyle, length);
}

class PoemSettingsConfig {
  final List<String> styles;
  final List<String> authorStyles;
  final List<int> lengths;

  const PoemSettingsConfig({
    required this.styles,
    required this.authorStyles,
    required this.lengths,
  });

  factory PoemSettingsConfig.fromJson(Map<String, dynamic> json) {
    return PoemSettingsConfig(
      styles: List<String>.from(json['styles'] as List),
      authorStyles: List<String>.from(json['authorStyles'] as List),
      lengths: List<int>.from(json['lengths'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'styles': styles,
      'authorStyles': authorStyles,
      'lengths': lengths,
    };
  }

  static const PoemSettingsConfig defaultConfig = PoemSettingsConfig(
    styles: [
      '낭만적인',
      '우울한',
      '철학적인',
      '초현실적인',
      '서정적인',
    ],
    authorStyles: [
      '김소월',
      '윤동주',
      '서정주',
      '김춘수',
      '정지용',
    ],
    lengths: [4, 8, 12, 16, 20],
  );
}