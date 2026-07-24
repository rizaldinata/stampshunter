import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stampshunter/app/theme/app_colors.dart';
import 'package:stampshunter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stampshunter/features/auth/presentation/widgets/auth_form.dart'
    show StampTextField, StampButton, StampDecoratedBox;
import 'package:stampshunter/features/profile/presentation/providers/profile_provider.dart';
import 'package:stampshunter/shared/utils/stamp_snackbar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;

  final _displayNameFocus = FocusNode();
  final _bioFocus = FocusNode();

  Uint8List? _avatarBytes;
  String? _avatarFilename;
  String? _currentAvatarUrl;

  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Fetch current user details from profileProvider & authProvider
    final authState = ref.read(authProvider);
    final user = authState.user;

    final profileAsync = ref.read(profileProvider('me'));
    final cachedProfile = profileAsync.value;

    final initialDisplayName = cachedProfile?.displayName ?? user?.displayName ?? '';
    final initialBio = cachedProfile?.bio ?? user?.bio ?? '';
    final initialAvatarUrl = cachedProfile?.avatarUrl ?? user?.avatarUrl;

    _displayNameController = TextEditingController(text: initialDisplayName);
    _bioController = TextEditingController(text: initialBio);
    _currentAvatarUrl = initialAvatarUrl;

    // Entrance Animation
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
    _displayNameController.dispose();
    _bioController.dispose();
    _displayNameFocus.dispose();
    _bioFocus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<ImageSource?> _showImageSourceBottomSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final sheetBg = isDark ? const Color(0xFF141414) : const Color(0xFFFFFDF9);

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        'SUMBER FOTO',
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
                  _ImageSourceTile(
                    icon: Icons.camera_alt_outlined,
                    title: 'Kamera',
                    subtitle: 'Ambil foto profil baru secara langsung',
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),
                  _ImageSourceTile(
                    icon: Icons.photo_library_outlined,
                    title: 'Galeri',
                    subtitle: 'Pilih foto profil dari galeri perangkat Anda',
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndCropImage() async {
    HapticFeedback.selectionClick();
    
    final ImageSource? source = await _showImageSourceBottomSheet();
    if (source == null) return;

    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ubah Foto Profil',
            toolbarColor: const Color(0xFF1E1A16),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            activeControlsWidgetColor: AppColors.primaryDarkTheme,
          ),
          IOSUiSettings(
            title: 'Ubah Foto Profil',
            aspectRatioLockEnabled: true,
            resetButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        final bytes = await croppedFile.readAsBytes();
        setState(() {
          _avatarBytes = bytes;
          _avatarFilename = pickedFile.name;
        });
      } else {
        // Fallback to picked file if cropped is cancelled
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _avatarBytes = bytes;
          _avatarFilename = pickedFile.name;
        });
      }
    } catch (e) {
      if (mounted) {
        showStampSnackBar(
          context,
          message: 'Gagal mengambil gambar. Pastikan izin akses diberikan.',
          type: StampSnackBarType.error,
        );
      }
    }
  }

  void _submitForm() async {
    FocusScope.of(context).unfocus(); // Clear keyboard focus first

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.lightImpact();

    await ref.read(editProfileProvider.notifier).updateProfile(
          displayName: _displayNameController.text.trim(),
          bio: _bioController.text.trim(),
          avatarBytes: _avatarBytes,
          avatarFilename: _avatarFilename,
        );
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(editProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF7F4F0);
    final primaryColor = isDark ? AppColors.primaryDarkTheme : AppColors.primary;

    // Listen to success / error states
    ref.listen<EditProfileState>(editProfileProvider, (previous, next) {
      if (next.isSuccess) {
        showStampSnackBar(
          context,
          message: 'Profil berhasil diperbarui.',
          type: StampSnackBarType.success,
        );
        ref.read(editProfileProvider.notifier).reset();
        context.pop();
      }

      if (next.error != null) {
        showStampSnackBar(
          context,
          message: next.error!,
          type: StampSnackBarType.error,
        );
        ref.read(editProfileProvider.notifier).reset();
      }
    });

    // Resolve current avatar display
    Widget avatarWidget;
    if (_avatarBytes != null) {
      avatarWidget = Image.memory(_avatarBytes!, fit: BoxFit.cover);
    } else if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      final fullUrl = _currentAvatarUrl!.startsWith('http')
          ? _currentAvatarUrl!
          : 'http://10.0.2.2:8000$_currentAvatarUrl';
      avatarWidget = CachedNetworkImage(
        imageUrl: fullUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: isDark ? const Color(0xFF222222) : const Color(0xFFE5DEC9),
          highlightColor: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF5F0EB),
          child: Container(color: Colors.white),
        ),
        errorWidget: (context, url, error) => _buildAvatarPlaceholder(),
      );
    } else {
      avatarWidget = _buildAvatarPlaceholder();
    }

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Ubah Profil',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
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
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          kToolbarHeight,
                      maxWidth: 480,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: SlideTransition(
                        position: _slideAnim,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 20),
                                // Avatar Picker
                                GestureDetector(
                                  onTap: _pickAndCropImage,
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        width: 110,
                                        height: 110,
                                        child: StampDecoratedBox(
                                          backgroundColor: isDark
                                              ? const Color(0xFF141414)
                                              : const Color(0xFFFFFDF9),
                                          borderColor: primaryColor.withValues(alpha: 0.4),
                                          borderWidth: 1.5,
                                          holeRadius: 4.5,
                                          holeSpacing: 11.0,
                                          shadowElevation: 3.0,
                                          shadowColor: Colors.black.withValues(alpha: 0.3),
                                          child: avatarWidget,
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: bg,
                                              width: 2.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.black,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Display Name Field
                                StampTextField(
                                  controller: _displayNameController,
                                  label: 'Nama Tampilan',
                                  hintText: 'Masukkan nama Anda',
                                  focusNode: _displayNameFocus,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: () =>
                                      FocusScope.of(context).requestFocus(_bioFocus),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Nama tampilan tidak boleh kosong';
                                    }
                                    if (value.trim().length > 100) {
                                      return 'Nama tampilan maksimal 100 karakter';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Bio Field
                                StampTextField(
                                  controller: _bioController,
                                  label: 'Biografi / Keterangan',
                                  hintText: 'Tulis sesuatu tentang diri Anda...',
                                  focusNode: _bioFocus,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: _submitForm,
                                  textCapitalization: TextCapitalization.sentences,
                                  validator: (value) {
                                    if (value != null && value.trim().length > 500) {
                                      return 'Biografi maksimal 500 karakter';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 36),

                                // Submit Button
                                StampButton(
                                  label: 'Simpan Perubahan',
                                  isLoading: editState.isLoading,
                                  onPressed: _submitForm,
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF141414) : const Color(0xFFFFFDF9),
      child: Icon(
        Icons.person_outline_rounded,
        size: 40,
        color: isDark ? const Color(0xFF4E4E4E) : const Color(0xFFB5AD9E),
      ),
    );
  }
}

class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
                  color: primary,
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
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
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
