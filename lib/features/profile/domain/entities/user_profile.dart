import 'package:stampshunter/features/auth/domain/entities/user.dart';

class UserProfile extends User {
  final int stampsCount;
  final int followersCount;
  final int followingCount;

  const UserProfile({
    required super.id,
    required super.username,
    required super.email,
    super.displayName,
    super.avatarUrl,
    super.bio,
    super.isVerified = false,
    required super.createdAt,
    required this.stampsCount,
    required this.followersCount,
    required this.followingCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      stampsCount: json['stamps_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }
}
