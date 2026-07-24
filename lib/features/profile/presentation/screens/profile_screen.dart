import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stampshunter/app/theme/app_colors.dart';
import 'package:stampshunter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stampshunter/features/auth/presentation/widgets/auth_form.dart' show StampDecoratedBox;
import 'package:stampshunter/features/profile/domain/entities/user_profile.dart';
import 'package:stampshunter/features/profile/presentation/providers/profile_provider.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp.dart';
import 'package:stampshunter/shared/utils/stamp_snackbar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    // Screen entrance animation (staggered fade + slide)
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    ));
    Future.microtask(() => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    // Invalidate profile and stamps
    ref.invalidate(profileProvider(widget.userId));
    ref.invalidate(userStampsProvider(widget.userId));
    // Wait for them to load again
    await ref.read(profileProvider(widget.userId).future);
    await ref.read(userStampsProvider(widget.userId).future);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isMe = widget.userId == 'me' || (authState.user != null && widget.userId == authState.user!.id);

    final profileAsync = ref.watch(profileProvider(widget.userId));
    final stampsAsync = ref.watch(userStampsProvider(widget.userId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF7F4F0);
    final primaryColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          isMe ? 'Arsip Saya' : 'Profil Pengumpul',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.userId != 'me' && Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                _showSettingsBottomSheet(context);
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -40,
            right: -70,
            child: IgnorePointer(
              child: CustomPaint(
                size: const Size(220, 220),
                painter: _PostmarkPainter(color: primaryColor),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: primaryColor,
              backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
              onRefresh: _onRefresh,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 480,
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SlideTransition(
                            position: _slideAnim,
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  profileAsync.when(
                                    data: (profile) => _buildProfileHeader(profile, isMe),
                                    loading: () => _buildProfileHeaderShimmer(),
                                    error: (err, _) => _buildErrorState(err.toString()),
                                  ),
                                  const SizedBox(height: 30),
                                  Text(
                                    'Koleksi Perangko'.toUpperCase(),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2.0,
                                      color: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9585),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  stampsAsync.when(
                                    data: (stamps) {
                                      if (stamps.isEmpty) {
                                        return _buildEmptyState(constraints.maxHeight - 310);
                                      }
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildStampsGrid(stamps),
                                          const SizedBox(height: 40),
                                        ],
                                      );
                                    },
                                    loading: () => Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildStampsGridShimmer(),
                                        const SizedBox(height: 40),
                                      ],
                                    ),
                                    error: (err, _) => const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFFA3A3A3) : const Color(0xFF666666);

    // Dynamic avatar url
    String avatarUrl = '';
    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      if (profile.avatarUrl!.startsWith('http')) {
        avatarUrl = profile.avatarUrl!;
      } else {
        avatarUrl = 'http://10.0.2.2:8000${profile.avatarUrl}';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Stamp Avatar
            SizedBox(
              width: 96,
              height: 96,
              child: StampDecoratedBox(
                backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFDF9),
                borderColor: primaryColor.withValues(alpha: 0.35),
                borderWidth: 1.5,
                holeRadius: 4.0,
                holeSpacing: 10.0,
                shadowElevation: 2.0,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                child: avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: isDark ? const Color(0xFF222222) : const Color(0xFFE5DEC9),
                          highlightColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF5F0EB),
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => _buildAvatarPlaceholder(),
                      )
                    : _buildAvatarPlaceholder(),
              ),
            ),
            const SizedBox(width: 24),
            // Profile Stats
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(profile.stampsCount.toString(), 'Stamp'),
                  _buildStatItem(profile.followersCount.toString(), 'Pengikut'),
                  _buildStatItem(profile.followingCount.toString(), 'Mengikuti'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Name & Username
        Text(
          profile.displayName ?? profile.username,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '@${profile.username}',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryColor.withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        // Bio
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          Text(
            profile.bio!,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w400,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Action Button
        if (isMe)
          OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/edit-profile');
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: BorderSide(color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5DEC9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Ubah Profil',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          )
        else
          OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              showStampSnackBar(
                context,
                message: 'Fitur mengikuti pengumpul akan hadir segera.',
                type: StampSnackBarType.info,
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              backgroundColor: primaryColor,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Ikuti',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF141414) : const Color(0xFFFFFDF9),
      child: Icon(
        Icons.person_outline_rounded,
        size: 38,
        color: isDark ? const Color(0xFF4E4E4E) : const Color(0xFFB5AD9E),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final labelColor = isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9585);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: labelColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStampsGrid(List<Stamp> stamps) {
    if (stamps.isEmpty) {
      return _buildEmptyState(180);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: stamps.length,
      itemBuilder: (context, index) {
        final stamp = stamps[index];
        return _buildStampItem(stamp);
      },
    );
  }

  Widget _buildStampItem(Stamp stamp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final thumbnail = stamp.thumbnailUrl ?? stamp.stampImageUrl ?? '';

    String imageUrl = '';
    if (thumbnail.isNotEmpty) {
      if (thumbnail.startsWith('http')) {
        imageUrl = thumbnail;
      } else {
        imageUrl = 'http://10.0.2.2:8000$thumbnail';
      }
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showStampSnackBar(
          context,
          message: stamp.title ?? 'Stamp detail',
          type: StampSnackBarType.info,
        );
      },
      child: StampDecoratedBox(
        backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFDF9),
        borderColor: primaryColor.withValues(alpha: 0.25),
        borderWidth: 1.0,
        holeRadius: 2.0,
        holeSpacing: 5.0,
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: isDark ? const Color(0xFF222222) : const Color(0xFFE5DEC9),
                  highlightColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF5F0EB),
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => _buildStampPlaceholder(),
              )
            : _buildStampPlaceholder(),
      ),
    );
  }

  Widget _buildStampPlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFDF9),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 20,
          color: isDark ? const Color(0xFF4E4E4E) : const Color(0xFFB5AD9E),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double minHeight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9585);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: minHeight > 180 ? minHeight : 180,
      ),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.markunread_mailbox_outlined,
                size: 48,
                color: mutedText.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Belum Ada Perangko',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Koleksi perangko yang Anda buat akan muncul di sini.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF222222) : const Color(0xFFE5DEC9);
    final highlightColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF5F0EB);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    3,
                    (index) => Column(
                      children: [
                        Container(width: 40, height: 16, color: Colors.white),
                        const SizedBox(height: 6),
                        Container(width: 60, height: 10, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(width: 150, height: 22, color: Colors.white),
          const SizedBox(height: 6),
          Container(width: 80, height: 12, color: Colors.white),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 40, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildStampsGridShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF222222) : const Color(0xFFE5DEC9);
    final highlightColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF5F0EB);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
            const SizedBox(height: 10),
            Text(
              'Gagal memuat profil',
              style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white60),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onRefresh,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final sheetBg = isDark ? const Color(0xFF141414) : const Color(0xFFFFFDF9);

    final profileAsync = ref.read(profileProvider(widget.userId));
    final profile = profileAsync.whenOrNull(data: (p) => p);

    String avatarUrl = '';
    if (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty) {
      if (profile.avatarUrl!.startsWith('http')) {
        avatarUrl = profile.avatarUrl!;
      } else {
        avatarUrl = 'http://10.0.2.2:8000${profile.avatarUrl}';
      }
    }

    final avatarWidget = avatarUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: avatarUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: isDark ? const Color(0xFF222222) : const Color(0xFFE5DEC9),
              highlightColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF5F0EB),
              child: Container(color: Colors.white),
            ),
            errorWidget: (context, url, error) => _buildAvatarPlaceholder(),
          )
        : _buildAvatarPlaceholder();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5DEC9),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text(
                          'PENGATURAN ARSIP',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (profile != null) ...[
                      StampDecoratedBox(
                        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFBF9F6),
                        borderColor: primaryColor.withValues(alpha: 0.2),
                        borderWidth: 1.0,
                        holeRadius: 3.0,
                        holeSpacing: 8.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 52,
                                height: 52,
                                child: StampDecoratedBox(
                                  backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFDF9),
                                  borderColor: primaryColor.withValues(alpha: 0.25),
                                  borderWidth: 0.8,
                                  holeRadius: 2.0,
                                  holeSpacing: 6.0,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: avatarWidget,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      profile.displayName ?? profile.username,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '@${profile.username}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      profile.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        color: isDark ? const Color(0xFF888888) : const Color(0xFF9E9585),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _SettingsTile(
                      icon: Icons.edit_document,
                      title: 'Ubah Profil',
                      subtitle: 'Perbarui nama, biografi, dan foto arsip Anda',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/edit-profile');
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'Keluar dari Akun',
                      subtitle: 'Putuskan sesi dan keluar dari aplikasi ini',
                      iconColor: AppColors.error,
                      textColor: AppColors.error,
                      onTap: () {
                        Navigator.of(context).pop();
                        _showLogoutConfirmationDialog(context);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: StampDecoratedBox(
              backgroundColor: isDark ? const Color(0xFF141414) : const Color(0xFFFFFDF9),
              borderColor: primaryColor.withValues(alpha: 0.35),
              borderWidth: 1.5,
              holeRadius: 3.5,
              holeSpacing: 9.0,
              shadowElevation: 6.0,
              shadowColor: Colors.black.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.2), width: 1),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'KONFIRMASI KELUAR',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Apakah Anda yakin ingin mengakhiri sesi dan keluar dari StampsHunter?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFA3A3A3) : const Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              side: BorderSide(
                                color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5DEC9),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              Navigator.of(context).pop();
                              ref.read(authProvider.notifier).logout();
                              showStampSnackBar(
                                context,
                                message: 'Anda berhasil keluar dari akun.',
                                type: StampSnackBarType.success,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              backgroundColor: AppColors.error,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Keluar',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFBF9F6);
    final border = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5DEC9);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: StampDecoratedBox(
          backgroundColor: bg,
          borderColor: border,
          borderWidth: 1.0,
          holeRadius: 3.0,
          holeSpacing: 8.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? primary,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor ?? (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF888888) : const Color(0xFF9E9585),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? const Color(0xFF4E4E4E) : const Color(0xFFB5AD9E),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostmarkPainter extends CustomPainter {
  final Color color;
  _PostmarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final circlePaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(c, r, circlePaint);
    canvas.drawCircle(
        c, r - 10, circlePaint..color = color.withValues(alpha: 0.035));

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final y = c.dy - 18 + (i * 12.0);
      canvas.drawLine(Offset(c.dx - r * 0.55, y), Offset(c.dx + r * 0.55, y),
          linePaint);
    }
  }

  @override
  bool shouldRepaint(_PostmarkPainter old) => old.color != color;
}
