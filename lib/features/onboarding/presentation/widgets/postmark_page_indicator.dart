import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Indikator halaman bergaya cap pos (postmark seal) dengan efek sliding smooth.
/// Menggantikan dots biasa sesuai PRD Section 4A.
///
/// Seluruh indikator digambar dalam satu kanvas CustomPaint sehingga
/// cap pos aktif dapat meluncur (slide) secara dinamis mengikuti pergerakan scroll.
class PostmarkPageIndicator extends StatelessWidget {
  final int count;
  final double pageOffset; // Nilai desimal posisi halaman dari PageController
  final Color activeColor;
  final Color inactiveColor;
  final double size;
  final double gap;

  const PostmarkPageIndicator({
    super.key,
    required this.count,
    required this.pageOffset,
    this.activeColor = const Color(0xFF8B4513),
    this.inactiveColor = const Color(0xFFBFB5A8),
    this.size = 14,
    this.gap = 10,
  });

  @override
  Widget build(BuildContext context) {
    // Tambahkan padding 8.0 agar ring luar (+2px di setiap sisi) dari cap aktif tidak terpotong
    final totalWidth = count * size + (count - 1) * gap + 8.0;
    final totalHeight = size + 8.0;

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: CustomPaint(
        painter: _PostmarkIndicatorPainter(
          count: count,
          pageOffset: pageOffset,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          dotSize: size,
          gap: gap,
        ),
      ),
    );
  }
}

class _PostmarkIndicatorPainter extends CustomPainter {
  final int count;
  final double pageOffset;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double gap;

  const _PostmarkIndicatorPainter({
    required this.count,
    required this.pageOffset,
    required this.activeColor,
    required this.inactiveColor,
    required this.dotSize,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double step = dotSize + gap;
    final double startX = 4.0 + dotSize / 2; // Titik awal koordinat X ditambah padding luar
    final double centerY = size.height / 2;
    final double radius = dotSize / 2;

    // ── 1. Menggambar semua cap pos nonaktif (background) ───────────────────
    final outlinePaint = Paint()
      ..color = inactiveColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final int teethCount = 10;
    final double teethRadius = radius * 0.22;

    for (int i = 0; i < count; i++) {
      final cx = startX + i * step;
      final center = Offset(cx, centerY);

      // Gambar lingkaran bergerigi kecil (stamp perforations)
      final path = Path();
      for (int t = 0; t < teethCount; t++) {
        final angle = (2 * math.pi / teethCount) * t;
        final toothCenter = Offset(
          center.dx + (radius - teethRadius) * math.cos(angle),
          center.dy + (radius - teethRadius) * math.sin(angle),
        );

        if (t == 0) {
          path.moveTo(
            toothCenter.dx + teethRadius * math.cos(angle),
            toothCenter.dy + teethRadius * math.sin(angle),
          );
        }

        path.arcToPoint(
          Offset(
            toothCenter.dx - teethRadius * math.cos(angle),
            toothCenter.dy - teethRadius * math.sin(angle),
          ),
          radius: Radius.circular(teethRadius),
          clockwise: false,
        );
      }
      path.close();
      canvas.drawPath(path, outlinePaint);

      // Titik kecil di tengah
      canvas.drawCircle(
        center,
        radius * 0.2,
        Paint()..color = inactiveColor.withValues(alpha: 0.4),
      );
    }

    // ── 2. Menggambar cap pos aktif yang meluncur (sliding seal) ───────────────
    final double activeCx = startX + pageOffset * step;
    final activeCenter = Offset(activeCx, centerY);

    // Lingkaran terisi
    final fillPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(activeCenter, radius, fillPaint);

    // Garis pembatalan pos (wavy cancellation lines)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: activeCenter, radius: radius - 0.5));
    canvas.save();
    canvas.clipPath(clipPath);

    for (int i = -1; i <= 1; i++) {
      final offsetY = activeCenter.dy + i * 3.0;
      final path = Path()
        ..moveTo(activeCenter.dx - radius, offsetY - 1)
        ..quadraticBezierTo(
          activeCenter.dx - radius / 2,
          offsetY + 1.5,
          activeCenter.dx,
          offsetY,
        )
        ..quadraticBezierTo(
          activeCenter.dx + radius / 2,
          offsetY - 1.5,
          activeCenter.dx + radius,
          offsetY + 1,
        );
      canvas.drawPath(path, linePaint);
    }
    canvas.restore();

    // Ring tipis di luar cap aktif
    final ringPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(activeCenter, radius + 2, ringPaint);
  }

  @override
  bool shouldRepaint(_PostmarkIndicatorPainter oldDelegate) =>
      oldDelegate.pageOffset != pageOffset ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.inactiveColor != inactiveColor;
}
