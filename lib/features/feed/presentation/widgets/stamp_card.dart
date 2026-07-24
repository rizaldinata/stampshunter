import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stampshunter/app/theme/app_colors.dart';
import 'package:stampshunter/features/feed/domain/entities/stamp_card.dart';
import 'package:stampshunter/features/feed/presentation/providers/feed_provider.dart';

class StampCardWidget extends ConsumerWidget {
  final StampCard card;

  const StampCardWidget({super.key, required this.card});

  String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'http://10.0.2.2:8000$url';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}h yang lalu';
    }
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final border = isDark ? AppColors.outlineDark : Colors.black12;

    final avatarUrl = _resolveUrl(card.avatarUrl);
    final stampUrl = _resolveUrl(card.thumbnailUrl ?? card.stampImageUrl);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: User Profile info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () => context.push('/profile/${card.userId}'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      backgroundImage: avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl.isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: isDark ? Colors.white60 : Colors.black54,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Display name & Username
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/profile/${card.userId}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.displayName ?? card.username,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '@${card.username}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white60 : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Timestamp
                  Text(
                    _formatDate(card.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // Stamp Image
            GestureDetector(
              onTap: () => context.push('/stamp/${card.id}'),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  width: double.infinity,
                  color: isDark ? Colors.black26 : const Color(0xFFF9F6F0),
                  child: Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                        // Retro stamp scalloped simulation wrapper
                        border: Border.all(
                          color: const Color(0xFFE5DDC8),
                          width: 2.0,
                        ),
                      ),
                      child: stampUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: stampUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: isDark ? Colors.white10 : Colors.black12,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image_outlined),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // Title and Action buttons
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (card.title != null && card.title!.isNotEmpty) ...[
                    Text(
                      card.title!.toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      // Like Action
                      GestureDetector(
                        onTap: () => ref.read(stampActionProvider.notifier).toggleLike(card.id),
                        child: Row(
                          children: [
                            Icon(
                              card.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: card.isLiked ? Colors.red : (isDark ? Colors.white60 : AppColors.textSecondary),
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${card.likesCount}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Comment Action
                      GestureDetector(
                        onTap: () => context.push('/stamp/${card.id}'),
                        child: Row(
                          children: [
                            Icon(
                              Icons.mode_comment_outlined,
                              color: isDark ? Colors.white60 : AppColors.textSecondary,
                              size: 19,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${card.commentsCount}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
