import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stampshunter/features/stamp/domain/entities/stamp_style.dart';

class StampBorderPainter extends CustomPainter {
  final double toothSize;
  final double toothSpacing;
  final double borderWidth;
  final Color borderColor;

  StampBorderPainter({
    required this.toothSize,
    required this.toothSpacing,
    required this.borderWidth,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    // Save layer to allow BlendMode.clear to punch transparent holes
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 1. Draw solid outer border
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 2. Punch out the inner photo area
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        borderWidth,
        borderWidth,
        size.width - borderWidth * 2,
        size.height - borderWidth * 2,
      ),
      clearPaint,
    );

    // 3. Punch out teeth along horizontal edges (top and bottom)
    final punchPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;

    final double step = max(4.0, toothSpacing * 2.0);

    for (double x = 0; x < size.width; x += step) {
      // Top edge
      canvas.drawOval(
        Rect.fromLTWH(x - toothSize / 2, -toothSize / 2, toothSize, toothSize),
        punchPaint,
      );
      // Bottom edge
      canvas.drawOval(
        Rect.fromLTWH(x - toothSize / 2, size.height - toothSize / 2, toothSize, toothSize),
        punchPaint,
      );
    }

    // 4. Punch out teeth along vertical edges (left and right)
    for (double y = 0; y < size.height; y += step) {
      // Left edge
      canvas.drawOval(
        Rect.fromLTWH(-toothSize / 2, y - toothSize / 2, toothSize, toothSize),
        punchPaint,
      );
      // Right edge
      canvas.drawOval(
        Rect.fromLTWH(size.width - toothSize / 2, y - toothSize / 2, toothSize, toothSize),
        punchPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StampBorderPainter oldDelegate) {
    return oldDelegate.toothSize != toothSize ||
        oldDelegate.toothSpacing != toothSpacing ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderColor != borderColor;
  }
}

class GrainPainter extends CustomPainter {
  final double grain;
  final double intensity;

  GrainPainter({required this.grain, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (grain <= 0 || intensity <= 0) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08 * grain * intensity)
      ..style = PaintingStyle.fill;

    final random = Random(42); // Seed fixed for static paper texture look
    final count = (size.width * size.height * grain * intensity * 0.15).toInt();
    for (int i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 0.8 + 0.4;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GrainPainter oldDelegate) {
    return oldDelegate.grain != grain || oldDelegate.intensity != intensity;
  }
}

class StampPreview extends StatelessWidget {
  final String imagePath;
  final StampStyle style;
  final double size;

  const StampPreview({
    super.key,
    required this.imagePath,
    required this.style,
    this.size = 280.0,
  });

  @override
  Widget build(BuildContext context) {
    final double borderWidth = style.border.enabled ? style.border.borderWidth.toDouble() : 0.0;

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            // 1. Photo and effect layer
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(borderWidth),
                child: ClipRect(
                  child: Stack(
                    children: [
                      // Raw image
                      Positioned.fill(
                        child: ColorFiltered(
                          colorFilter: ColorFilter.matrix(_calculateColorMatrix(style.filter)),
                          child: Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Vignette overlay
                      if (style.filter.enabled && style.filter.vignette > 0)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(style.filter.vignette * style.filter.intensity * 0.7),
                                ],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      // Grain/noise overlay
                      if (style.filter.enabled && style.filter.grain > 0)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GrainPainter(
                              grain: style.filter.grain,
                              intensity: style.filter.intensity,
                            ),
                          ),
                        ),
                      // Template overlay
                      if (style.template.enabled)
                        Positioned.fill(
                          child: _buildTemplateOverlay(style.template),
                        ),
                      // Text overlays
                      if (style.textEnabled)
                        ...style.textOverlays.map((text) => _buildTextOverlay(text)),
                    ],
                  ),
                ),
              ),
            ),
            // 2. Perforated Border overlay
            if (style.border.enabled)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: StampBorderPainter(
                      toothSize: style.border.toothSize.toDouble(),
                      toothSpacing: style.border.toothSpacing.toDouble(),
                      borderWidth: style.border.borderWidth.toDouble(),
                      borderColor: style.border.borderColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Color Matrix Calculation ──

  List<double> _calculateColorMatrix(FilterConfig config) {
    if (!config.enabled) {
      return [
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ];
    }

    final intensity = config.intensity;
    final warmth = config.warmth;
    final sepia = config.sepia;

    // Base values
    double rR = 1.0; double rG = 0.0; double rB = 0.0;
    double gR = 0.0; double gG = 1.0; double gB = 0.0;
    double bR = 0.0; double bG = 0.0; double bB = 1.0;

    double rOffset = 20.0 * intensity;
    double gOffset = 20.0 * intensity;
    double bOffset = 20.0 * intensity;

    // Apply color grading lift/gain
    rR *= 0.95;
    gG *= 0.95;
    bB *= 0.95;

    // Apply sepia blending
    if (sepia > 0) {
      const sR_R = 0.393; const sR_G = 0.769; const sR_B = 0.189;
      const sG_R = 0.349; const sG_G = 0.686; const sG_B = 0.168;
      const sB_R = 0.272; const sB_G = 0.534; const sB_B = 0.131;

      rR = rR * (1 - sepia) + sR_R * sepia;
      rG = rG * (1 - sepia) + sR_G * sepia;
      rB = rB * (1 - sepia) + sR_B * sepia;

      gR = gR * (1 - sepia) + sG_R * sepia;
      gG = gG * (1 - sepia) + sG_G * sepia;
      gB = gB * (1 - sepia) + sG_B * sepia;

      bR = bR * (1 - sepia) + sB_R * sepia;
      bG = bG * (1 - sepia) + sB_G * sepia;
      bB = bB * (1 - sepia) + sB_B * sepia;
    }

    // Apply warmth (Warm up/cool down channels)
    if (warmth > 0) {
      rOffset += warmth * 25.0 * intensity;
      gOffset += warmth * 12.0 * intensity;
      bOffset -= warmth * 18.0 * intensity;
    }

    // Blend final matrix with identity based on intensity
    final outRR = rR * intensity + (1 - intensity);
    final outRG = rG * intensity;
    final outRB = rB * intensity;

    final outGR = gR * intensity;
    final outGG = gG * intensity + (1 - intensity);
    final outGB = gB * intensity;

    final outBR = bR * intensity;
    final outBG = bG * intensity;
    final outBB = bB * intensity + (1 - intensity);

    return [
      outRR, outRG, outRB, 0, rOffset,
      outGR, outGG, outGB, 0, gOffset,
      outBR, outBG, outBB, 0, bOffset,
      0,     0,     0,     1, 0,
    ];
  }

  // ── Template Drawing Helper ──

  Widget _buildTemplateOverlay(TemplateConfig config) {
    return CustomPaint(
      painter: _TemplatePainter(frameColor: config.frameColor),
    );
  }

  // ── Text Overlay Drawing Helper ──

  Widget _buildTextOverlay(TextOverlayConfig config) {
    Alignment alignment;
    switch (config.position) {
      case 'top':
        alignment = Alignment.topCenter;
        break;
      case 'left':
        alignment = Alignment.centerLeft;
        break;
      case 'right':
        alignment = Alignment.centerRight;
        break;
      case 'center':
        alignment = Alignment.center;
        break;
      case 'bottom':
      default:
        alignment = Alignment.bottomCenter;
        break;
    }

    final double margin = config.margin.toDouble();
    final padding = EdgeInsets.only(
      top: config.position == 'top' ? margin : 0,
      bottom: config.position == 'bottom' ? margin + 5 : 0,
      left: config.position == 'left' ? margin : 0,
      right: config.position == 'right' ? margin : 0,
    );

    TextStyle baseStyle;
    switch (config.fontFamily) {
      case 'sans-serif':
        baseStyle = GoogleFonts.montserrat(fontWeight: FontWeight.w800);
        break;
      case 'monospace':
        baseStyle = GoogleFonts.robotoMono(fontWeight: FontWeight.bold);
        break;
      case 'readable':
        baseStyle = GoogleFonts.lora(fontWeight: FontWeight.w600);
        break;
      case 'script':
        baseStyle = GoogleFonts.dancingScript(fontWeight: FontWeight.w900);
        break;
      case 'serif':
      default:
        baseStyle = GoogleFonts.playfairDisplay(fontWeight: FontWeight.w800);
        break;
    }

    // Scaling the font size slightly based on preview container size vs full image scale
    final textStyle = baseStyle.copyWith(
      fontSize: config.fontSize * (size / 360.0), // Scale relative to default 360px editor size
      color: config.fontColor,
      letterSpacing: 1.0,
      shadows: [
        Shadow(
          offset: const Offset(1, 1),
          blurRadius: 2.0,
          color: config.fontColor.computeLuminance() > 0.5 ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.8),
        ),
      ],
    );

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: Text(
          config.content.toUpperCase(),
          style: textStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TemplatePainter extends CustomPainter {
  final Color frameColor;

  _TemplatePainter({required this.frameColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = frameColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final w = size.width;
    final h = size.height;

    // Draw frame rectangle
    canvas.drawRect(Rect.fromLTWH(8, 8, w - 16, h - 16), paint);

    // Corner accents
    final fillPaint = Paint()
      ..color = frameColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(const Rect.fromLTWH(8, 8, 12, 12), fillPaint);
    canvas.drawRect(Rect.fromLTWH(w - 20, 8, 12, 12), fillPaint);
    canvas.drawRect(Rect.fromLTWH(8, h - 20, 12, 12), fillPaint);
    canvas.drawRect(Rect.fromLTWH(w - 20, h - 20, 12, 12), fillPaint);
  }

  @override
  bool shouldRepaint(covariant _TemplatePainter oldDelegate) {
    return oldDelegate.frameColor != frameColor;
  }
}
