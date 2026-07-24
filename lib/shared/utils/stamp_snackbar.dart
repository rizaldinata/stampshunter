import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stampshunter/app/theme/app_colors.dart';

// ─── Tipe Snackbar ───────────────────────────────────────────────────────────

enum StampSnackBarType { success, error, warning, info }

// ─── Konfigurasi per tipe ────────────────────────────────────────────────────

class _TypeConfig {
  final IconData icon;
  final Color color;
  final String defaultTitle;

  const _TypeConfig({
    required this.icon,
    required this.color,
    required this.defaultTitle,
  });
}

const _typeConfigs = <StampSnackBarType, _TypeConfig>{
  StampSnackBarType.success: _TypeConfig(
    icon: Icons.check_circle_outline_rounded,
    color: AppColors.success,
    defaultTitle: 'Berhasil',
  ),
  StampSnackBarType.error: _TypeConfig(
    icon: Icons.error_outline_rounded,
    color: AppColors.error,
    defaultTitle: 'Terjadi Kesalahan',
  ),
  StampSnackBarType.warning: _TypeConfig(
    icon: Icons.warning_amber_rounded,
    color: AppColors.warning,
    defaultTitle: 'Perhatian',
  ),
  StampSnackBarType.info: _TypeConfig(
    icon: Icons.info_outline_rounded,
    color: AppColors.info,
    defaultTitle: 'Info',
  ),
};

// ─── Helper Function — gunakan ini di seluruh aplikasi ───────────────────────

void showStampSnackBar(
  BuildContext context, {
  required String message,
  String? title,
  StampSnackBarType type = StampSnackBarType.info,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final config = _typeConfigs[type]!;

  // Haptic sesuai severity (Professional UX)
  switch (type) {
    case StampSnackBarType.error:
      HapticFeedback.heavyImpact();
    case StampSnackBarType.warning:
      HapticFeedback.mediumImpact();
    case StampSnackBarType.success:
    case StampSnackBarType.info:
      HapticFeedback.lightImpact();
  }

  // clearSnackBars agar tidak stack kalau dipanggil cepat
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: EdgeInsets.zero,
        // Professional UX: Center dan Constrain lebar maksimal snackbar agar tidak melebar jelek di tablet/landscape
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420, // Batas lebar optimal untuk keterbacaan
            ),
            child: _StampSnackBarWidget(
              title: title ?? config.defaultTitle,
              message: message,
              typeColor: config.color,
              actionLabel: actionLabel,
              onAction: onAction,
            ),
          ),
        ),
      ),
    );
}

// ─── Widget Internal ─────────────────────────────────────────────────────────

class _StampSnackBarWidget extends StatelessWidget {
  final String title;
  final String message;
  final Color typeColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StampSnackBarWidget({
    required this.title,
    required this.message,
    required this.typeColor,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // Warm dark — "tinta di atas kertas gelap" — konsisten di light & dark mode
    const bgColor = Color(0xFF1E1A16);
    const textColor = Colors.white;
    final mutedTextColor = Colors.white.withValues(alpha: 0.70); // Kontras rasio yang lebih ramah mata

    return CustomPaint(
      painter: _StampSnackbarPainter(
        backgroundColor: bgColor,
        borderColor: typeColor.withValues(alpha: 0.45),
        borderWidth: 1.2,
        holeRadius: 3.0,
        holeSpacing: 7.0,
        shadowElevation: 4.0,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        typeColor: typeColor,
      ),
      child: ClipPath(
        clipper: _StampSnackbarClipper(
          holeRadius: 3.0,
          holeSpacing: 7.0,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent strip (cuts into the stamp teeth)
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: typeColor,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      typeColor,
                      typeColor.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Playfair Display title for class/postage look
                            Text(
                              title,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: 0.1,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Montserrat message text
                            Text(
                              message,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: mutedTextColor,
                                height: 1.45,
                              ),
                            ),

                            // Action button (optional)
                            if (actionLabel != null && onAction != null) ...[
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  onAction!();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.08), // Lebih kokoh dan berkesan tombol
                                    border: Border.all(color: typeColor.withValues(alpha: 0.3), width: 0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    actionLabel!.toUpperCase(),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: typeColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Close button — Professional UX: minimum touch target area
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).clearSnackBars(),
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white30,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Custom Stamp Clip & Paint for SnackBar ───────────────────────────────────

Path _buildStampPath(Size size, double holeRadius, double holeSpacing) {
  final path = Path();
  final double step = 2 * holeRadius + holeSpacing;

  void traceEdge(Offset p1, Offset p2) {
    final vector = p2 - p1;
    final distance = vector.distance;
    final direction = vector / distance;

    int count = ((distance - holeSpacing) / step).floor();
    if (count < 1) {
      path.lineTo(p2.dx, p2.dy);
      return;
    }

    final double totalHolesWidth = count * 2 * holeRadius + (count - 1) * holeSpacing;
    final double margin = (distance - totalHolesWidth) / 2;

    Offset current = p1 + direction * margin;
    path.lineTo(current.dx, current.dy);

    for (int i = 0; i < count; i++) {
      current = current + direction * (2 * holeRadius);
      path.arcToPoint(
        current,
        radius: Radius.circular(holeRadius),
        clockwise: false,
        largeArc: false,
      );

      if (i < count - 1) {
        current = current + direction * holeSpacing;
        path.lineTo(current.dx, current.dy);
      }
    }

    path.lineTo(p2.dx, p2.dy);
  }

  path.moveTo(0, 0);
  traceEdge(const Offset(0, 0), Offset(size.width, 0));
  traceEdge(Offset(size.width, 0), Offset(size.width, size.height));
  traceEdge(Offset(size.width, size.height), Offset(0, size.height));
  traceEdge(Offset(0, size.height), const Offset(0, 0));
  path.close();
  return path;
}

class _StampSnackbarClipper extends CustomClipper<Path> {
  final double holeRadius;
  final double holeSpacing;

  const _StampSnackbarClipper({
    required this.holeRadius,
    required this.holeSpacing,
  });

  @override
  Path getClip(Size size) => _buildStampPath(size, holeRadius, holeSpacing);

  @override
  bool shouldReclip(_StampSnackbarClipper oldClipper) =>
      oldClipper.holeRadius != holeRadius || oldClipper.holeSpacing != holeSpacing;
}

class _StampSnackbarPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double holeRadius;
  final double holeSpacing;
  final double shadowElevation;
  final Color shadowColor;
  final Color typeColor;

  const _StampSnackbarPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.holeRadius,
    required this.holeSpacing,
    required this.shadowElevation,
    required this.shadowColor,
    required this.typeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildStampPath(size, holeRadius, holeSpacing);

    // Draw shadow
    if (shadowElevation > 0) {
      canvas.drawShadow(
        path,
        shadowColor,
        shadowElevation,
        true,
      );
    }

    // Draw background
    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw subtle postmark patterns (wavy lines) on the background
    final postmarkPaint = Paint()
      ..color = typeColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // A circular cancellation postmark on the right of the snackbar
    if (size.width > 120) {
      final cancelCenter = Offset(size.width - 50, size.height / 2);
      canvas.drawCircle(cancelCenter, 24, postmarkPaint);
      canvas.drawCircle(cancelCenter, 18, postmarkPaint);

      // Wavy postmark lines crossing the snackbar
      final wavePath = Path();
      for (double y = 8; y < size.height; y += 14) {
        wavePath.moveTo(size.width - 100, y);
        wavePath.quadraticBezierTo(
          size.width - 75, y - 4,
          size.width - 50, y,
        );
        wavePath.quadraticBezierTo(
          size.width - 25, y + 4,
          size.width, y,
        );
      }
      canvas.drawPath(wavePath, postmarkPaint);
    }

    // Draw outer stamp border
    if (borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, borderPaint);
    }

    // Draw an inner solid inset border (typical of classic stamps)
    final inset = holeRadius + 2.0;
    if (size.width > inset * 2 && size.height > inset * 2) {
      final insetRect = Rect.fromLTWH(
        inset,
        inset,
        size.width - (inset * 2),
        size.height - (inset * 2),
      );
      final insetPaint = Paint()
        ..color = typeColor.withValues(alpha: 0.12)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawRect(insetRect, insetPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StampSnackbarPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.holeRadius != holeRadius ||
        oldDelegate.holeSpacing != holeSpacing ||
        oldDelegate.shadowElevation != shadowElevation ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.typeColor != typeColor;
  }
}
