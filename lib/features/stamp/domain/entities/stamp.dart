class Stamp {
  final String id;
  final String userId;
  final String? originalImageUrl;
  final String? stampImageUrl;
  final String? thumbnailUrl;
  final String? title;
  final String? description;
  final Map<String, dynamic>? stampStyle;
  final List<String>? tags;
  final bool isPublic;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Stamp({
    required this.id,
    required this.userId,
    this.originalImageUrl,
    this.stampImageUrl,
    this.thumbnailUrl,
    this.title,
    this.description,
    this.stampStyle,
    this.tags,
    this.isPublic = true,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Stamp.fromJson(Map<String, dynamic> json) {
    return Stamp(
      id: json['id'],
      userId: json['user_id'],
      originalImageUrl: json['original_image_url'],
      stampImageUrl: json['stamp_image_url'],
      thumbnailUrl: json['thumbnail_url'],
      title: json['title'],
      description: json['description'],
      stampStyle: json['stamp_style'] != null
          ? Map<String, dynamic>.from(json['stamp_style'])
          : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isPublic: json['is_public'] ?? true,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      viewsCount: json['views_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}
