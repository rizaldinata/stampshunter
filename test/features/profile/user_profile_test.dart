import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stampshunter/features/profile/domain/entities/user_profile.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp.dart';
import 'package:stampshunter/features/profile/domain/repositories/profile_repository.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  group('UserProfile Entity', () {
    test('should parse valid full JSON correctly', () {
      final json = {
        'id': 'user-123',
        'username': 'testcollector',
        'email': 'collector@example.com',
        'display_name': 'Test Collector',
        'avatar_url': '/static/avatars/avatar.png',
        'bio': 'Collector of vintage stamp designs',
        'is_verified': true,
        'created_at': '2026-07-18T05:00:00Z',
        'stamps_count': 12,
        'followers_count': 45,
        'following_count': 30,
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'user-123');
      expect(profile.username, 'testcollector');
      expect(profile.email, 'collector@example.com');
      expect(profile.displayName, 'Test Collector');
      expect(profile.avatarUrl, '/static/avatars/avatar.png');
      expect(profile.bio, 'Collector of vintage stamp designs');
      expect(profile.isVerified, true);
      expect(profile.createdAt.isUtc, true);
      expect(profile.stampsCount, 12);
      expect(profile.followersCount, 45);
      expect(profile.followingCount, 30);
    });

    test('should parse JSON with missing optional fields correctly', () {
      final json = {
        'id': 'user-456',
        'username': 'litecollector',
        'created_at': '2026-07-18T05:00:00Z',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'user-456');
      expect(profile.username, 'litecollector');
      expect(profile.email, '');
      expect(profile.displayName, null);
      expect(profile.avatarUrl, null);
      expect(profile.bio, null);
      expect(profile.isVerified, false);
      expect(profile.stampsCount, 0);
      expect(profile.followersCount, 0);
      expect(profile.followingCount, 0);
    });
  });

  group('Stamp Entity', () {
    test('should parse valid Stamp JSON correctly', () {
      final json = {
        'id': 'stamp-789',
        'user_id': 'user-123',
        'original_image_url': '/original.png',
        'stamp_image_url': '/stamp.png',
        'thumbnail_url': '/thumb.png',
        'title': 'Vintage Postcard',
        'description': 'A beautiful 1920 stamp.',
        'stamp_style': {'color': 'red'},
        'tags': ['vintage', 'classic'],
        'is_public': true,
        'likes_count': 5,
        'comments_count': 2,
        'views_count': 42,
        'created_at': '2026-07-18T05:10:00Z',
      };

      final stamp = Stamp.fromJson(json);

      expect(stamp.id, 'stamp-789');
      expect(stamp.userId, 'user-123');
      expect(stamp.originalImageUrl, '/original.png');
      expect(stamp.stampImageUrl, '/stamp.png');
      expect(stamp.thumbnailUrl, '/thumb.png');
      expect(stamp.title, 'Vintage Postcard');
      expect(stamp.description, 'A beautiful 1920 stamp.');
      expect(stamp.stampStyle, {'color': 'red'});
      expect(stamp.tags, ['vintage', 'classic']);
      expect(stamp.isPublic, true);
      expect(stamp.likesCount, 5);
      expect(stamp.commentsCount, 2);
      expect(stamp.viewsCount, 42);
      expect(stamp.createdAt.isUtc, true);
    });
  });

  group('ProfileRepository Mock', () {
    final mockRepo = MockProfileRepository();

    test('should return UserProfile mock when getMe is called', () async {
      final dummyProfile = UserProfile(
        id: 'user-mocked',
        username: 'mocked',
        email: 'mock@example.com',
        createdAt: DateTime.now(),
        stampsCount: 5,
        followersCount: 10,
        followingCount: 15,
      );

      when(() => mockRepo.getMe(any())).thenAnswer((_) async => dummyProfile);

      final result = await mockRepo.getMe('valid-token');

      expect(result.id, 'user-mocked');
      expect(result.username, 'mocked');
      expect(result.stampsCount, 5);
      verify(() => mockRepo.getMe('valid-token')).called(1);
    });
  });
}
