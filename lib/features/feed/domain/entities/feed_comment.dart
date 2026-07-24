class FeedComment {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final String? parentId;
  final DateTime createdAt;

  const FeedComment({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    this.parentId,
    required this.createdAt,
  });

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return FeedComment(
      id: json['id'],
      userId: user['id'] ?? '',
      username: user['username'] ?? '',
      avatarUrl: user['avatar_url'],
      content: json['content'] ?? '',
      parentId: json['parent_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
