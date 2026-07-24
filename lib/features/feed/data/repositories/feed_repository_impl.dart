import 'package:stampshunter/features/feed/domain/entities/stamp_card.dart';
import 'package:stampshunter/features/feed/domain/entities/feed_comment.dart';
import 'package:stampshunter/features/feed/domain/repositories/feed_repository.dart';
import 'package:stampshunter/features/feed/data/datasources/feed_remote_datasource.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource remoteDataSource;

  FeedRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<StampCard>> getPublicFeed({
    int page = 1,
    int limit = 20,
    required String sort,
  }) {
    return remoteDataSource.getPublicFeed(
      page: page,
      limit: limit,
      sort: sort,
    );
  }

  @override
  Future<List<StampCard>> getFollowingFeed({
    int page = 1,
    int limit = 20,
  }) {
    return remoteDataSource.getFollowingFeed(
      page: page,
      limit: limit,
    );
  }

  @override
  Future<Map<String, dynamic>> toggleLike(String stampId) {
    return remoteDataSource.toggleLike(stampId);
  }

  @override
  Future<List<FeedComment>> getComments(
    String stampId, {
    int page = 1,
    int limit = 20,
  }) {
    return remoteDataSource.getComments(
      stampId,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<FeedComment> addComment(
    String stampId, {
    required String content,
    String? parentId,
  }) {
    return remoteDataSource.addComment(
      stampId,
      content: content,
      parentId: parentId,
    );
  }
}
