class Magazine {
  final int id;
  final String title;
  final String subtitle;
  final String coverImageUrl;
  final String contentUrl; // [추가] 기사 링크 (Notion, 블로그 등)
  final DateTime createdAt;

  Magazine({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverImageUrl,
    required this.contentUrl,
    required this.createdAt,
  });

  factory Magazine.fromJson(Map<String, dynamic> json) {
    return Magazine(
      id: json['id'] as int,
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      coverImageUrl: json['cover_image_url'] ?? '',
      contentUrl: json['content_url'] ?? '', // DB 컬럼명 확인 필요
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}