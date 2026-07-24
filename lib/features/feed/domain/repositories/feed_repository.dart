import 'package:stampshunter/features/feed/domain/entities/stamp_card.dart';
import 'package:stampshunter/features/feed/domain/entities/feed_comment.dart';

abstract class FeedRepository {
  Future<List<StampCard>> getPublicFeed({
    int page = 1,
    int limit = 20,
    required String sort,
  });

  Future<List<StampCard>> getFollowingFeed({
    int page = 1,
    int limit = 20,
  });

  Future<Map<String, dynamic>> toggleLike(String stampId);

  Future<List<FeedComment>> getComments(
    String stampId, {
    int page = 1,
    int limit = 20,
  });

  Future<FeedComment> addComment(
    String stampId, {
    required String content,
    String? parentId,
  });
}
