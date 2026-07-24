import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stampshunter/app/theme/app_colors.dart';

class SourcePickerSheet extends StatelessWidget {
  const SourcePickerSheet({super.key});

  static Future<ImageSourceOption?> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<ImageSourceOption>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const SourcePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : const Color(0xFFFFFDF9);
    final borderCol = isDark ? AppColors.outlineDark : const Color(0xFFE5DEC9);
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.onSurfaceVariantDark : AppColors.textSecondary;
    final primary = isDark ? AppColors.primaryDarkTheme : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(color: borderCol, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'PILIH SUMBER FOTO',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
                color: primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ambil foto baru atau pilih dari galeri peranti Anda.',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 20),

            // Camera Option
            _SourceOptionButton(
              icon: Icons.camera_alt_outlined,
              label: 'Kamera',
              description: 'Ambil foto objek secara langsung',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(ImageSourceOption.camera);
              },
              backgroundColor: bg,
              borderColor: borderCol,
              textColor: textColor,
              descriptionColor: mutedColor,
              iconColor: primary,
            ),
            const SizedBox(height: 12),

            // Gallery Option
            _SourceOptionButton(
              icon: Icons.photo_library_outlined,
              label: 'Galeri',
              description: 'Pilih foto yang sudah tersimpan',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(ImageSourceOption.gallery);
              },
              backgroundColor: bg,
              borderColor: borderCol,
              textColor: textColor,
              descriptionColor: mutedColor,
              iconColor: primary,
            ),
            const SizedBox(height: 12),

            // Cancel Button
            Center(
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  splashFactory: NoSplash.splashFactory,
                ),
                child: Text(
                  'BATAL',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ImageSourceOption { camera, gallery }

class _SourceOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color descriptionColor;
  final Color iconColor;

  const _SourceOptionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.descriptionColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 24, color: iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: descriptionColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: descriptionColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
