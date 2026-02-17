class Magazine {
  final String id;
  final String title;
  final String subtitle;
  final String coverImageUrl;
  final String content;
  final DateTime createdAt;
  final String? authorName;

  Magazine({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverImageUrl,
    required this.content,
    required this.createdAt,
    this.authorName,
  });

  factory Magazine.fromJson(Map<String, dynamic> json) {
    return Magazine(
      id: json['id'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      coverImageUrl: json['cover_image_url'] ?? '',
      content: json['content'] ?? '', // DB 컬럼명 content
      createdAt: DateTime.parse(json['created_at']),
      authorName: json['author_name'],
    );
  }
}