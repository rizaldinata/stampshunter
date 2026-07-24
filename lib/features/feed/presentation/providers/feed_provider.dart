import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stampshunter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stampshunter/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:stampshunter/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:stampshunter/features/feed/domain/entities/feed_comment.dart';
import 'package:stampshunter/features/feed/domain/entities/stamp_card.dart';
import 'package:stampshunter/features/feed/domain/repositories/feed_repository.dart';

part 'feed_provider.g.dart';

// ── Dependency Injection Providers ───────────────────────────────────────────

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final remote = FeedRemoteDataSource(dio: dio);
  return FeedRepositoryImpl(remoteDataSource: remote);
});

// ── Notifiers ────────────────────────────────────────────────────────────────

@riverpod
class PublicFeed extends _$PublicFeed {
  static const _pageSize = 20;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  Future<List<StampCard>> build({required String sort}) async {
    _currentPage = 1;
    _hasMore = true;
    return ref.read(feedRepositoryProvider).getPublicFeed(
          page: 1,
          limit: _pageSize,
          sort: sort,
        );
  }

  void updateStamps(List<StampCard> newStamps) {
    state = AsyncValue.data(newStamps);
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    
    final repository = ref.read(feedRepositoryProvider);
    _currentPage++;
    
    try {
      final newStamps = await repository.getPublicFeed(
        page: _currentPage,
        limit: _pageSize,
        sort: sort,
      );
      if (newStamps.length < _pageSize) {
        _hasMore = false;
      }
      state = AsyncValue.data([...state.value ?? [], ...newStamps]);
    } catch (e) {
      _currentPage--;
      // Keep state as is, error handles in scrolling UI if needed
    }
  }
}

@riverpod
class FollowingFeed extends _$FollowingFeed {
  static const _pageSize = 20;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  Future<List<StampCard>> build() async {
    _currentPage = 1;
    _hasMore = true;
    return ref.read(feedRepositoryProvider).getFollowingFeed(
          page: 1,
          limit: _pageSize,
        );
  }

  void updateStamps(List<StampCard> newStamps) {
    state = AsyncValue.data(newStamps);
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    
    final repository = ref.read(feedRepositoryProvider);
    _currentPage++;
    
    try {
      final newStamps = await repository.getFollowingFeed(
        page: _currentPage,
        limit: _pageSize,
      );
      if (newStamps.length < _pageSize) {
        _hasMore = false;
      }
      state = AsyncValue.data([...state.value ?? [], ...newStamps]);
    } catch (e) {
      _currentPage--;
    }
  }
}

@riverpod
class StampComments extends _$StampComments {
  @override
  Future<List<FeedComment>> build({required String stampId}) async {
    return ref.read(feedRepositoryProvider).getComments(stampId);
  }

  Future<void> addComment(String content) async {
    if (state.isLoading || !state.hasValue) return;

    final repository = ref.read(feedRepositoryProvider);
    final comment = await repository.addComment(stampId, content: content);

    state = AsyncValue.data([...state.value!, comment]);

    // Update the comments cached count in feeds
    _incrementCommentsCount(stampId);
  }

  void _incrementCommentsCount(String id) {
    List<StampCard> updateList(List<StampCard> list) {
      return list.map((card) {
        if (card.id == id) {
          return card.copyWith(commentsCount: card.commentsCount + 1);
        }
        return card;
      }).toList();
    }

    final publicTrending = ref.read(publicFeedProvider(sort: 'trending'));
    if (publicTrending.hasValue) {
      ref.read(publicFeedProvider(sort: 'trending').notifier).updateStamps(updateList(publicTrending.value!));
    }

    final publicRecent = ref.read(publicFeedProvider(sort: 'recent'));
    if (publicRecent.hasValue) {
      ref.read(publicFeedProvider(sort: 'recent').notifier).updateStamps(updateList(publicRecent.value!));
    }

    final following = ref.read(followingFeedProvider);
    if (following.hasValue) {
      ref.read(followingFeedProvider.notifier).updateStamps(updateList(following.value!));
    }
  }
}

@riverpod
class StampAction extends _$StampAction {
  @override
  void build() {}

  Future<void> toggleLike(String stampId) async {
    _updateFeedLikeState(stampId);

    try {
      final repository = ref.read(feedRepositoryProvider);
      await repository.toggleLike(stampId);
    } catch (e) {
      // Revert if API fails
      _updateFeedLikeState(stampId, revert: true);
    }
  }

  void _updateFeedLikeState(String stampId, {bool revert = false}) {
    List<StampCard> updateList(List<StampCard> list) {
      return list.map((card) {
        if (card.id == stampId) {
          final isLiked = revert ? !card.isLiked : !card.isLiked;
          final offset = isLiked ? 1 : -1;
          return card.copyWith(
            isLiked: isLiked,
            likesCount: max(0, card.likesCount + offset),
          );
        }
        return card;
      }).toList();
    }

    final publicTrending = ref.read(publicFeedProvider(sort: 'trending'));
    if (publicTrending.hasValue) {
      ref.read(publicFeedProvider(sort: 'trending').notifier).updateStamps(updateList(publicTrending.value!));
    }

    final publicRecent = ref.read(publicFeedProvider(sort: 'recent'));
    if (publicRecent.hasValue) {
      ref.read(publicFeedProvider(sort: 'recent').notifier).updateStamps(updateList(publicRecent.value!));
    }

    final following = ref.read(followingFeedProvider);
    if (following.hasValue) {
      ref.read(followingFeedProvider.notifier).updateStamps(updateList(following.value!));
    }
  }
}
