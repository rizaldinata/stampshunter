import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Satu slide onboarding: ilustrasi + judul + deskripsi.
/// Ilustrasi menggunakan CustomPainter (sepia/monokrom) sesuai PRD.
class OnboardingPageItem extends StatelessWidget {
  final String title;
  final String description;
  final CustomPainter illustrationPainter;
  final double parallaxOffset; // nilai dari PageController listener

  const OnboardingPageItem({
    super.key,
    required this.title,
    required this.description,
    required this.illustrationPainter,
    this.parallaxOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenH < 680;
    final illustrationH = screenH * (isSmall ? 0.42 : 0.48);

    const sepiaText = Color(0xFF4A3728);
    const mutedText = Color(0xFF7A6A5A);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Ilustrasi dengan efek parallax ────────────────────────────────
              Transform.translate(
                offset: Offset(parallaxOffset * 40, 0),
                child: SizedBox(
                  height: illustrationH,
                  width: double.infinity,
                  child: CustomPaint(painter: illustrationPainter),
                ),
              ),
              SizedBox(height: isSmall ? 28 : 40),

              // ── Judul ─────────────────────────────────────────────────────────
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: isSmall ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  color: sepiaText,
                  height: 1.25,
                ),
              ),
              SizedBox(height: isSmall ? 12 : 16),

              // ── Deskripsi ─────────────────────────────────────────────────────
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: mutedText,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ILUSTRASI 1 — Hunt: Kaca pembesar + amplop antik + peta
// ═════════════════════════════════════════════════════════════════════════════

class HuntIllustrationPainter extends CustomPainter {
  const HuntIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Warna sepia
    final sepiaStroke = Paint()
      ..color = const Color(0xFF8B6F47)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final sepiaFill = Paint()
      ..color = const Color(0xFFF5ECD7)
      ..style = PaintingStyle.fill;

    final sepiaAccent = Paint()
      ..color = const Color(0xFF6B4423)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final faintPaint = Paint()
      ..color = const Color(0xFFD4B896)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // ── Peta latar (sketsa sederhana) ──────────────────────────────────────
    final mapRect = Rect.fromCenter(
      center: Offset(cx, cy + 10),
      width: size.width * 0.72,
      height: size.height * 0.55,
    );
    canvas.drawRect(mapRect, sepiaFill);
    canvas.drawRect(mapRect, faintPaint);

    // Garis grid peta
    for (int i = 1; i < 4; i++) {
      final x = mapRect.left + mapRect.width / 4 * i;
      canvas.drawLine(
        Offset(x, mapRect.top),
        Offset(x, mapRect.bottom),
        faintPaint,
      );
    }
    for (int i = 1; i < 3; i++) {
      final y = mapRect.top + mapRect.height / 3 * i;
      canvas.drawLine(
        Offset(mapRect.left, y),
        Offset(mapRect.right, y),
        faintPaint,
      );
    }

    // Bentuk daratan sederhana di peta
    final landPath = Path()
      ..moveTo(mapRect.left + 20, mapRect.top + mapRect.height * 0.3)
      ..quadraticBezierTo(cx - 30, mapRect.top + 15, cx + 10,
          mapRect.top + mapRect.height * 0.25)
      ..quadraticBezierTo(
          mapRect.right - 20,
          mapRect.top + mapRect.height * 0.35,
          mapRect.right - 15,
          mapRect.top + mapRect.height * 0.55)
      ..quadraticBezierTo(cx, mapRect.top + mapRect.height * 0.65,
          mapRect.left + 25, mapRect.top + mapRect.height * 0.5)
      ..close();
    canvas.drawPath(landPath, Paint()..color = const Color(0xFFD4B896));
    canvas.drawPath(landPath, faintPaint);

    // Titik-titik lokasi di peta
    for (final pt in [
      Offset(cx - 30, cy - 10),
      Offset(cx + 40, cy - 25),
      Offset(cx - 10, cy + 20),
    ]) {
      canvas.drawCircle(pt, 3, Paint()..color = const Color(0xFF8B4513));
      canvas.drawCircle(pt, 6, sepiaAccent);
    }

    // ── Amplop antik (pojok kiri bawah peta) ──────────────────────────────
    final envRect = Rect.fromLTWH(
      mapRect.left - 10,
      mapRect.bottom - 45,
      70,
      48,
    );
    canvas.drawRect(envRect, sepiaFill);
    canvas.drawRect(envRect, sepiaStroke);

    // Diagonal amplop
    canvas.drawLine(envRect.topLeft, Offset(envRect.left + 35, envRect.top + 22),
        sepiaAccent);
    canvas.drawLine(
        envRect.topRight, Offset(envRect.left + 35, envRect.top + 22), sepiaAccent);

    // ── Kaca pembesar (tengah-atas) ────────────────────────────────────────
    final lensCenter = Offset(cx + 15, cy - size.height * 0.08);
    const lensRadius = 52.0;

    // Bayangan lensa
    canvas.drawCircle(
      lensCenter + const Offset(3, 3),
      lensRadius,
      Paint()..color = const Color(0x22000000),
    );
    // Lingkaran lensa
    canvas.drawCircle(
        lensCenter, lensRadius, Paint()..color = const Color(0xB0EAF6F8));
    canvas.drawCircle(lensCenter, lensRadius, sepiaStroke..strokeWidth = 4);

    // Highlight lensa
    canvas.drawArc(
      Rect.fromCircle(center: lensCenter, radius: lensRadius - 8),
      -math.pi * 0.8,
      math.pi * 0.35,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Gagang kaca pembesar
    final handleStart = lensCenter + Offset(lensRadius * 0.7, lensRadius * 0.7);
    final handleEnd = handleStart + const Offset(30, 30);
    canvas.drawLine(
      handleStart,
      handleEnd,
      Paint()
        ..color = const Color(0xFF5C3A1E)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      handleStart,
      handleEnd,
      Paint()
        ..color = const Color(0xFF8B5E3C)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// ILUSTRASI 2 — Archive: Album prangko + penjepit (tweezers)
// ═════════════════════════════════════════════════════════════════════════════

class ArchiveIllustrationPainter extends CustomPainter {
  const ArchiveIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final sepia = Paint()
      ..color = const Color(0xFF8B6F47)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = const Color(0xFFF5ECD7)
      ..style = PaintingStyle.fill;

    final accent = Paint()
      ..color = const Color(0xFF6B4423)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // ── Buku album ─────────────────────────────────────────────────────────
    final bookRect = Rect.fromCenter(
        center: Offset(cx, cy + 5), width: size.width * 0.65, height: size.height * 0.58);
    // Shadow
    canvas.drawRect(
      bookRect.shift(const Offset(4, 4)),
      Paint()..color = const Color(0x22000000),
    );
    // Cover album
    canvas.drawRect(
        bookRect, Paint()..color = const Color(0xFF5C3A1E));
    // Halaman dalam
    final pageRect = bookRect.deflate(8);
    canvas.drawRect(pageRect, fill);
    canvas.drawRect(pageRect, sepia);

    // Spiral binding (punggung buku)
    for (double y = bookRect.top + 12; y < bookRect.bottom - 8; y += 14) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(bookRect.left + 4, y), width: 10, height: 8),
        Paint()
          ..color = const Color(0xFF8B6F47)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Judul album (garis)
    canvas.drawLine(
        Offset(pageRect.left + 10, pageRect.top + 15),
        Offset(pageRect.right - 10, pageRect.top + 15),
        accent);
    canvas.drawLine(
        Offset(pageRect.left + 10, pageRect.top + 22),
        Offset(pageRect.right - 30, pageRect.top + 22),
        accent);

    // ── 4 slot prangko di album ────────────────────────────────────────────
    final slots = [
      Rect.fromLTWH(pageRect.left + 12, pageRect.top + 34, 52, 42),
      Rect.fromLTWH(pageRect.left + 74, pageRect.top + 34, 52, 42),
      Rect.fromLTWH(pageRect.left + 12, pageRect.top + 84, 52, 42),
      Rect.fromLTWH(pageRect.left + 74, pageRect.top + 84, 52, 42),
    ];

    for (int i = 0; i < slots.length; i++) {
      final s = slots[i];
      // Corner mounts (penempel prangko)
      for (final corner in [s.topLeft, s.topRight, s.bottomLeft, s.bottomRight]) {
        final mountRect = Rect.fromCenter(center: corner, width: 8, height: 8);
        canvas.drawRect(mountRect,
            Paint()..color = const Color(0xFFD4B896)..style = PaintingStyle.fill);
      }
      // Slot outline (perforated look)
      _drawPerforatedRect(canvas, s, accent);

      // Isi slot ke-1 dan ke-3 dengan prangko "terisi"
      if (i % 2 == 0) {
        canvas.drawRect(s.deflate(5), Paint()..color = const Color(0xFFE8D5B5));
        canvas.drawRect(s.deflate(5), accent);
        // Gambar sederhana di dalam prangko
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(s.center.dx, s.center.dy - 3), width: 20, height: 16),
          accent,
        );
      }
    }

    // ── Penjepit prangko (tweezers) di kanan bawah ─────────────────────────
    final twStart1 = Offset(bookRect.right + 8, bookRect.top + 20);
    final twStart2 = Offset(bookRect.right + 20, bookRect.top + 20);
    final twEnd = Offset(bookRect.right + 14, bookRect.bottom - 10);

    canvas.drawLine(twStart1, twEnd,
        Paint()
          ..color = const Color(0xFF8B6F47)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(twStart2, twEnd,
        Paint()
          ..color = const Color(0xFF8B6F47)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round);
    // Ujung penjepit
    canvas.drawLine(twEnd, twEnd + const Offset(-5, 8),
        sepia..strokeWidth = 3);
    canvas.drawLine(twEnd, twEnd + const Offset(5, 8),
        sepia..strokeWidth = 3);
  }

  void _drawPerforatedRect(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()..addRect(rect);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// ILUSTRASI 3 — Showcase: Bola dunia + jalur airmail + amplop terbang
// ═════════════════════════════════════════════════════════════════════════════

class ShowcaseIllustrationPainter extends CustomPainter {
  const ShowcaseIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final sepia = Paint()
      ..color = const Color(0xFF8B6F47)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final accent = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final faint = Paint()
      ..color = const Color(0xFFD4B896)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // ── Bola dunia ─────────────────────────────────────────────────────────
    final globeCenter = Offset(cx, cy + 5);
    const globeRadius = 68.0;

    canvas.drawCircle(
        globeCenter,
        globeRadius,
        Paint()..color = const Color(0xFFF0E8D5)..style = PaintingStyle.fill);

    // Garis lintang
    for (int i = -2; i <= 2; i++) {
      if (i == 0) continue;
      final latY = globeCenter.dy + i * (globeRadius / 2.5);
      final halfW = math.sqrt(math.max(
          0, globeRadius * globeRadius - (latY - globeCenter.dy) * (latY - globeCenter.dy)));
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(globeCenter.dx, latY),
            width: halfW * 2,
            height: (globeRadius * 0.3)),
        0,
        math.pi,
        false,
        faint,
      );
    }

    // Garis bujur (3 elips vertikal)
    for (final xOffset in [-0.5, 0.0, 0.5]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(globeCenter.dx + xOffset * globeRadius, globeCenter.dy),
            width: math.max(4, globeRadius * (1 - xOffset.abs())),
            height: globeRadius * 2),
        faint,
      );
    }

    // Border bola
    canvas.drawCircle(globeCenter, globeRadius, sepia);

    // ── Jalur airmail (kurva Bezier dari dan ke globe) ─────────────────────
    final routes = [
      // Kiri-atas ke kanan-bawah
      (
        Offset(globeCenter.dx - globeRadius * 0.8, globeCenter.dy - globeRadius * 0.5),
        Offset(globeCenter.dx + globeRadius * 0.9, globeCenter.dy + globeRadius * 0.4),
        Offset(globeCenter.dx, globeCenter.dy - globeRadius * 0.8),
      ),
      // Atas ke kanan
      (
        Offset(globeCenter.dx - 10, globeCenter.dy - globeRadius),
        Offset(globeCenter.dx + globeRadius * 0.9, globeCenter.dy - 20),
        Offset(globeCenter.dx + globeRadius * 0.3, globeCenter.dy - globeRadius * 0.7),
      ),
    ];

    final routePaint = Paint()
      ..color = const Color(0xFF8B4513).withValues(alpha: 0.55)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final (start, end, ctrl) in routes) {
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);

      // Garis putus-putus (dashed)
      _drawDashedPath(canvas, path, routePaint);

      // Arrow kecil di ujung
      final dir = (end - ctrl).normalized();
      canvas.drawLine(
        end,
        end - Offset(dir.dx * 7 - dir.dy * 4, dir.dy * 7 + dir.dx * 4),
        routePaint,
      );
      canvas.drawLine(
        end,
        end - Offset(dir.dx * 7 + dir.dy * 4, dir.dy * 7 - dir.dx * 4),
        routePaint,
      );
    }

    // ── Amplop terbang (kanan-atas) ────────────────────────────────────────
    final envCenter = Offset(cx + globeRadius * 0.75, cy - globeRadius * 0.7);
    _drawFlyingEnvelope(canvas, envCenter, sepia, accent);

    // ── Amplop terbang (kiri-bawah) ────────────────────────────────────────
    final envCenter2 =
        Offset(cx - globeRadius * 0.85, cy + globeRadius * 0.55);
    _drawFlyingEnvelope(canvas, envCenter2, sepia, accent, scale: 0.7);
  }

  void _drawFlyingEnvelope(
    Canvas canvas,
    Offset center,
    Paint strokePaint,
    Paint accentPaint, {
    double scale = 1.0,
  }) {
    final w = 38.0 * scale;
    final h = 26.0 * scale;
    final rect = Rect.fromCenter(center: center, width: w, height: h);

    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFFF5ECD7)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(rect, strokePaint..strokeWidth = 1.5 * scale);

    // Lipatan amplop
    canvas.drawLine(rect.topLeft, center + Offset(0, -h * 0.1), accentPaint);
    canvas.drawLine(rect.topRight, center + Offset(0, -h * 0.1), accentPaint);

    // Garis merah-putih (airmail stripes)
    final stripePaint = Paint()
      ..color = const Color(0xFF8B4513).withValues(alpha: 0.5)
      ..strokeWidth = 2.0 * scale;

    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(rect.left + i * (w / 4), rect.bottom),
        Offset(rect.left + i * (w / 4) + w / 4, rect.bottom),
        i.isEven ? stripePaint : (Paint()..color = Colors.transparent),
      );
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashLen = 5.0;
    const gapLen = 3.0;

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      while (dist < metric.length) {
        final end = math.min(dist + dashLen, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension on Offset {
  Offset normalized() {
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return Offset.zero;
    return Offset(dx / len, dy / len);
  }
}
