class PoetryTemplate {
  final String id;
  final String title;
  final String content;
  final List<String> keywords;
  final DateTime createdAt;

  const PoetryTemplate({
    required this.id,
    required this.title,
    required this.content,
    required this.keywords,
    required this.createdAt,
  });

  factory PoetryTemplate.fromJson(Map<String, dynamic> json) {
    return PoetryTemplate(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      keywords: List<String>.from(json['keywords']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'keywords': keywords,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PoetryTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
