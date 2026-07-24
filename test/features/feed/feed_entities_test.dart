import 'package:flutter_test/flutter_test.dart';
import 'package:stampshunter/features/feed/domain/entities/stamp_card.dart';
import 'package:stampshunter/features/feed/domain/entities/feed_comment.dart';

void main() {
  group('StampCard Entity', () {
    test('should parse valid StampCard JSON correctly', () {
      final json = {
        'id': 'stamp-123',
        'user': {
          'id': 'user-456',
          'username': 'stamps_creator',
          'display_name': 'Creator Name',
          'avatar_url': 'http://avatar.png'
        },
        'thumbnail_url': 'http://thumb.png',
        'stamp_image_url': 'http://stamp.png',
        'title': 'Monas Stamp',
        'likes_count': 10,
        'comments_count': 5,
        'is_liked': true,
        'created_at': '2026-07-24T08:00:00Z',
      };

      final stamp = StampCard.fromJson(json);

      expect(stamp.id, 'stamp-123');
      expect(stamp.userId, 'user-456');
      expect(stamp.username, 'stamps_creator');
      expect(stamp.displayName, 'Creator Name');
      expect(stamp.avatarUrl, 'http://avatar.png');
      expect(stamp.thumbnailUrl, 'http://thumb.png');
      expect(stamp.stampImageUrl, 'http://stamp.png');
      expect(stamp.title, 'Monas Stamp');
      expect(stamp.likesCount, 10);
      expect(stamp.commentsCount, 5);
      expect(stamp.isLiked, true);
      expect(stamp.createdAt.isUtc, true);
    });

    test('should parse JSON with missing optional fields correctly', () {
      final json = {
        'id': 'stamp-789',
        'user': {
          'id': 'user-999',
          'username': 'stranger',
        },
        'created_at': '2026-07-24T09:00:00Z',
      };

      final stamp = StampCard.fromJson(json);

      expect(stamp.id, 'stamp-789');
      expect(stamp.userId, 'user-999');
      expect(stamp.username, 'stranger');
      expect(stamp.displayName, null);
      expect(stamp.avatarUrl, null);
      expect(stamp.thumbnailUrl, null);
      expect(stamp.likesCount, 0);
      expect(stamp.commentsCount, 0);
      expect(stamp.isLiked, false);
    });

    test('should copyWith correctly', () {
      final stamp = StampCard(
        id: '1',
        userId: 'user1',
        username: 'user1',
        likesCount: 1,
        commentsCount: 2,
        isLiked: false,
        createdAt: DateTime.now(),
      );

      final updated = stamp.copyWith(
        likesCount: 5,
        isLiked: true,
      );

      expect(updated.likesCount, 5);
      expect(updated.commentsCount, 2);
      expect(updated.isLiked, true);
    });
  });

  group('FeedComment Entity', () {
    test('should parse valid FeedComment JSON correctly', () {
      final json = {
        'id': 'comment-123',
        'user': {
          'id': 'user-456',
          'username': 'commenter',
          'avatar_url': 'http://avatar.png'
        },
        'content': 'Loving the retro look!',
        'parent_id': 'comment-parent',
        'created_at': '2026-07-24T08:30:00Z',
      };

      final comment = FeedComment.fromJson(json);

      expect(comment.id, 'comment-123');
      expect(comment.userId, 'user-456');
      expect(comment.username, 'commenter');
      expect(comment.avatarUrl, 'http://avatar.png');
      expect(comment.content, 'Loving the retro look!');
      expect(comment.parentId, 'comment-parent');
      expect(comment.createdAt.isUtc, true);
    });
  });
}
