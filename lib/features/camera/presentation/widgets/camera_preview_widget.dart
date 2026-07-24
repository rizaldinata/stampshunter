import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stampshunter/app/theme/app_colors.dart';
import 'package:stampshunter/features/auth/presentation/widgets/auth_form.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final bool isInitialized;
  final bool hasPermission;
  final VoidCallback onRetryPermission;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.isInitialized,
    required this.hasPermission,
    required this.onRetryPermission,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : const Color(0xFFFFFDF9);
    final primary = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final mutedColor = isDark ? AppColors.onSurfaceVariantDark : AppColors.textSecondary;

    if (!hasPermission) {
      return Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Beautiful Postal-Noir styled badge for warning
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 28,
                      color: primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'AKSES KAMERA DIPERLUKAN',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                  color: primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              Text(
                'StampsHunter memerlukan izin akses kamera agar Anda dapat mengambil foto stamp secara langsung.',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                  color: mutedColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              StampButton(
                label: 'Buka Pengaturan',
                onPressed: () async {
                  await openAppSettings();
                  onRetryPermission();
                },
              ),
            ],
          ),
        ),
      );
    }

    if (!isInitialized || controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: CameraPreview(controller!),
      ),
    );
  }
}
