import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stampshunter/app/theme/app_colors.dart';
import 'package:stampshunter/features/feed/presentation/providers/feed_provider.dart';
import 'package:stampshunter/features/feed/presentation/widgets/comment_section.dart';
import 'package:stampshunter/features/profile/presentation/providers/profile_provider.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp.dart';
import 'package:stampshunter/features/stamp/presentation/providers/stamp_editor_provider.dart';

final stampDetailProvider = FutureProvider.family<Stamp, String>((ref, stampId) async {
  final repository = ref.watch(stampRepositoryProvider);
  return repository.getStamp(stampId);
});

class StampDetailScreen extends ConsumerStatefulWidget {
  final String stampId;

  const StampDetailScreen({super.key, required this.stampId});

  @override
  ConsumerState<StampDetailScreen> createState() => _StampDetailScreenState();
}

class _StampDetailScreenState extends ConsumerState<StampDetailScreen> {
  String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'http://10.0.2.2:8000$url';
  }

  bool _isLikedInFeeds(String id) {
    // Check trending
    final trending = ref.read(publicFeedProvider(sort: 'trending')).valueOrNull;
    if (trending != null) {
      for (final card in trending) {
        if (card.id == id) return card.isLiked;
      }
    }
    // Check recent
    final recent = ref.read(publicFeedProvider(sort: 'recent')).valueOrNull;
    if (recent != null) {
      for (final card in recent) {
        if (card.id == id) return card.isLiked;
      }
    }
    // Check following
    final following = ref.read(followingFeedProvider).valueOrNull;
    if (following != null) {
      for (final card in following) {
        if (card.id == id) return card.isLiked;
      }
    }
    return false;
  }

  int _likesCountInFeeds(String id, int defaultCount) {
    final trending = ref.read(publicFeedProvider(sort: 'trending')).valueOrNull;
    if (trending != null) {
      for (final card in trending) {
        if (card.id == id) return card.likesCount;
      }
    }
    return defaultCount;
  }

  int _commentsCountInFeeds(String id, int defaultCount) {
    final trending = ref.read(publicFeedProvider(sort: 'trending')).valueOrNull;
    if (trending != null) {
      for (final card in trending) {
        if (card.id == id) return card.commentsCount;
      }
    }
    return defaultCount;
  }

  void _showCommentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return CommentSection(stampId: widget.stampId);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stampAsync = ref.watch(stampDetailProvider(widget.stampId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : const Color(0xFFFFFDF9);
    final activeColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final cardBg = isDark ? Colors.black26 : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'DETAIL STAMP',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: stampAsync.when(
        data: (stamp) {
          final authorAsync = ref.watch(profileProvider(stamp.userId));
          final stampUrl = _resolveUrl(stamp.stampImageUrl ?? stamp.thumbnailUrl);
          
          final isLiked = _isLikedInFeeds(stamp.id);
          final likesCount = _likesCountInFeeds(stamp.id, stamp.likesCount);
          final commentsCount = _commentsCountInFeeds(stamp.id, stamp.commentsCount);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Full Stamp Card Image
                Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        )
                      ],
                      border: Border.all(
                        color: const Color(0xFFE5DDC8),
                        width: 2.5,
                      ),
                    ),
                    child: stampUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: stampUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.broken_image_outlined, size: 48),
                            ),
                          )
                        : const Center(child: Icon(Icons.image, size: 48)),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Author Profile Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: authorAsync.when(
                    data: (profile) {
                      final avatarUrl = _resolveUrl(profile.avatarUrl);
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isDark ? Colors.white10 : Colors.black12,
                            backgroundImage: avatarUrl.isNotEmpty
                                ? CachedNetworkImageProvider(avatarUrl)
                                : null,
                            child: avatarUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.displayName ?? profile.username,
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '@${profile.username}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white60 : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      height: 40,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (err, stack) => const Text('Gagal memuat profil pembuat'),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Divider(),
                ),

                // 3. Title, Description, and Tags
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stamp.title != null && stamp.title!.isNotEmpty) ...[
                        Text(
                          stamp.title!.toUpperCase(),
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (stamp.description != null && stamp.description!.isNotEmpty) ...[
                        Text(
                          stamp.description!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Tags row
                      if (stamp.tags != null && stamp.tags!.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: stamp.tags!.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: activeColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Dibuat pada ${DateFormat('dd MMMM yyyy HH:mm').format(stamp.createdAt.toLocal())}',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.white30 : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Divider(),
                ),

                // 4. Like / Comment Summary and triggers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      // Like
                      InkWell(
                        onTap: () => ref.read(stampActionProvider.notifier).toggleLike(stamp.id),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isLiked ? Colors.red : (isDark ? Colors.white60 : AppColors.textSecondary),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$likesCount Likes',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Comment sheet trigger
                      InkWell(
                        onTap: () => _showCommentsBottomSheet(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.mode_comment_outlined,
                                color: isDark ? Colors.white60 : AppColors.textSecondary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$commentsCount Komentar',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Gagal memuat detail stamp: $err'),
        ),
      ),
    );
  }
}
