class StampCard {
  final String id;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? thumbnailUrl;
  final String? stampImageUrl;
  final String? title;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;

  const StampCard({
    required this.id,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.thumbnailUrl,
    this.stampImageUrl,
    this.title,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  StampCard copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
  }) {
    return StampCard(
      id: id,
      userId: userId,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      thumbnailUrl: thumbnailUrl,
      stampImageUrl: stampImageUrl,
      title: title,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
    );
  }

  factory StampCard.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return StampCard(
      id: json['id'],
      userId: user['id'] ?? '',
      username: user['username'] ?? '',
      displayName: user['display_name'],
      avatarUrl: user['avatar_url'],
      thumbnailUrl: json['thumbnail_url'],
      stampImageUrl: json['stamp_image_url'],
      title: json['title'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
