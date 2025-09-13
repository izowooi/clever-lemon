class DailyQuote {
  final String id;
  final String title;
  final String content;
  final List<String> keywords;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final bool isFromTemplate;
  final String? templateId;

  const DailyQuote({
    required this.id,
    required this.title,
    required this.content,
    required this.keywords,
    required this.createdAt,
    this.modifiedAt,
    this.isFromTemplate = false,
    this.templateId,
  });

  DailyQuote copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? keywords,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isFromTemplate,
    String? templateId,
  }) {
    return DailyQuote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      keywords: keywords ?? this.keywords,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isFromTemplate: isFromTemplate ?? this.isFromTemplate,
      templateId: templateId ?? this.templateId,
    );
  }

  factory DailyQuote.fromJson(Map<String, dynamic> json) {
    return DailyQuote(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      keywords: List<String>.from(json['keywords']),
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt:
          json['modifiedAt'] != null ? DateTime.parse(json['modifiedAt']) : null,
      isFromTemplate: json['isFromTemplate'] ?? false,
      templateId: json['templateId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'keywords': keywords,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'isFromTemplate': isFromTemplate,
      'templateId': templateId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyQuote && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
