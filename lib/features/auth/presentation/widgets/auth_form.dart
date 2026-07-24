import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stampshunter/app/theme/app_colors.dart';

// ─── StampTextField ─────────────────────────────────────────────────────────
// "Archive Document" style — left accent border that turns amber on focus.
// Inspired by vintage postal/document forms. No generic box border.

class StampTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  // UX: keyboard action button (Next vs Done)
  final TextInputAction? textInputAction;
  // UX: external FocusNode untuk navigasi antar-field
  final FocusNode? focusNode;
  // UX: callback saat user tekan action button di keyboard
  final VoidCallback? onFieldSubmitted;
  // UX: matikan autocorrect/suggestions untuk field sensitif
  final bool autocorrect;
  final bool enableSuggestions;
  // UX: capitalization mode per field
  final TextCapitalization textCapitalization;

  const StampTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<StampTextField> createState() => _StampTextFieldState();
}

class _StampTextFieldState extends State<StampTextField>
    with SingleTickerProviderStateMixin {
  // Gunakan external FocusNode jika disediakan, atau buat internal
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool _isFocused = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    _effectiveFocusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_handleTextChanged);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    final focused = _effectiveFocusNode.hasFocus;
    setState(() => _isFocused = focused);
    focused ? _ctrl.forward() : _ctrl.reverse();
  }

  void _handleTextChanged() {
    if (_errorText != null) {
      setState(() {
        _errorText = null;
      });
    }
  }

  @override
  void didUpdateWidget(StampTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika focusNode diganti, update listener
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_onFocusChanged);
      _effectiveFocusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    _effectiveFocusNode.removeListener(_onFocusChanged);
    // Hanya dispose internal FocusNode; external node dikelola oleh parent
    _internalFocusNode?.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDarkTheme : AppColors.primary;

    final backgroundColor = isDark ? const Color(0xFF141414) : const Color(0xFFFFFDF9);
    final idleBorderColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5DEC9);
    final activeBorderColor = primary;

    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final hintColor = isDark ? const Color(0xFF4E4E4E) : const Color(0xFFB5AD9E);
    final labelColor = _errorText != null
        ? AppColors.error
        : (_isFocused ? primary : (isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9585)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: GoogleFonts.montserrat(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
            color: labelColor,
          ),
          child: Text(widget.label.toUpperCase()),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final double animVal = _anim.value;
            
            Color borderColor;
            double borderWidth;
            double shadowElevation;

            if (_errorText != null) {
              borderColor = AppColors.error;
              borderWidth = 1.8;
              shadowElevation = 1.0;
            } else {
              borderColor = Color.lerp(idleBorderColor, activeBorderColor, animVal)!;
              borderWidth = 1.3 + (animVal * 0.5);
              shadowElevation = animVal * 3.0;
            }

            return StampDecoratedBox(
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              borderWidth: borderWidth,
              shadowElevation: shadowElevation,
              shadowColor: isDark ? Colors.black.withValues(alpha: 0.5) : primary.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: widget.controller,
                        focusNode: _effectiveFocusNode,
                        obscureText: widget.obscureText,
                        keyboardType: widget.keyboardType,
                        // UX: tombol keyboard Next/Done sesuai posisi field
                        textInputAction: widget.textInputAction,
                        // UX: matikan autocorrect & kapitalisasi untuk field sensitif
                        autocorrect: widget.autocorrect,
                        enableSuggestions: widget.enableSuggestions,
                        textCapitalization: widget.textCapitalization,
                        // UX: callback saat tekan Next/Done di keyboard
                        onFieldSubmitted: (_) => widget.onFieldSubmitted?.call(),
                        validator: (value) {
                          final err = widget.validator?.call(value);
                          if (err != _errorText) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _errorText = err;
                                });
                              }
                            });
                          }
                          return err;
                        },
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: GoogleFonts.montserrat(
                            color: hintColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          errorStyle: const TextStyle(height: 0, fontSize: 0),
                        ),
                      ),
                    ),
                    if (widget.suffixIcon != null) ...[
                      const SizedBox(width: 8),
                      widget.suffixIcon!,
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: _errorText == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: GoogleFonts.montserrat(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── AuthTextField ───────────────────────────────────────────────────────────
// Legacy outlined field — kept for backward compatibility.

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? hintText;
  final Widget? suffixIcon;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.hintText,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─── UnderlinedTextField ─────────────────────────────────────────────────────
// Legacy underline field — kept for backward compatibility.

class UnderlinedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? hintText;
  final Widget? suffixIcon;

  const UnderlinedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.hintText,
    this.suffixIcon,
  });

  @override
  State<UnderlinedTextField> createState() => _UnderlinedTextFieldState();
}

class _UnderlinedTextFieldState extends State<UnderlinedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _lineAnim;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _lineAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _focusNode.addListener(() {
      final focused = _focusNode.hasFocus;
      if (focused != _isFocused) {
        setState(() => _isFocused = focused);
        focused ? _animController.forward() : _animController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final labelColor = _isFocused
        ? primary
        : (isDark ? AppColors.onSurfaceVariantDark : AppColors.textTertiary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: GoogleFonts.montserrat(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
          child: Text(widget.label.toUpperCase()),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              style: GoogleFonts.montserrat(
                color: isDark ? AppColors.onSurfaceDark : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: GoogleFonts.montserrat(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.2),
                  fontSize: 14,
                ),
                suffixIcon: widget.suffixIcon,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 10, right: 36),
                errorStyle: GoogleFonts.montserrat(
                    fontSize: 10, color: AppColors.error),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _lineAnim,
                builder: (_, _) => Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    widthFactor: _lineAnim.value,
                    child: Container(height: 1.5, color: primary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Stamp Custom Shape & Painters ──────────────────────────────────────────

Path buildStampPath(Size size, double holeRadius, double holeSpacing) {
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

class StampClipper extends CustomClipper<Path> {
  final double holeRadius;
  final double holeSpacing;

  const StampClipper({
    this.holeRadius = 3.5,
    this.holeSpacing = 8.0,
  });

  @override
  Path getClip(Size size) => buildStampPath(size, holeRadius, holeSpacing);

  @override
  bool shouldReclip(StampClipper oldClipper) =>
      oldClipper.holeRadius != holeRadius || oldClipper.holeSpacing != holeSpacing;
}

class StampPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double holeRadius;
  final double holeSpacing;
  final double shadowElevation;
  final Color shadowColor;

  const StampPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.holeRadius,
    required this.holeSpacing,
    required this.shadowElevation,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildStampPath(size, holeRadius, holeSpacing);

    if (shadowElevation > 0) {
      canvas.drawShadow(
        path,
        shadowColor,
        shadowElevation,
        true,
      );
    }

    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    if (borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(StampPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.holeRadius != holeRadius ||
        oldDelegate.holeSpacing != holeSpacing ||
        oldDelegate.shadowElevation != shadowElevation ||
        oldDelegate.shadowColor != shadowColor;
  }
}

class StampDecoratedBox extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double holeRadius;
  final double holeSpacing;
  final double shadowElevation;
  final Color shadowColor;

  const StampDecoratedBox({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    this.borderWidth = 1.5,
    this.holeRadius = 3.5,
    this.holeSpacing = 8.0,
    this.shadowElevation = 0.0,
    this.shadowColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StampPainter(
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
        holeRadius: holeRadius,
        holeSpacing: holeSpacing,
        shadowElevation: shadowElevation,
        shadowColor: shadowColor,
      ),
      child: ClipPath(
        clipper: StampClipper(
          holeRadius: holeRadius,
          holeSpacing: holeSpacing,
        ),
        child: child,
      ),
    );
  }
}

class StampButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;

  const StampButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final defaultBg = primary;
    final defaultText = isDark ? Colors.black : Colors.white;

    final bg = backgroundColor ?? defaultBg;
    final textCol = textColor ?? defaultText;

    final isEnabled = onPressed != null && !isLoading;

    // Disabled styles
    final finalBg = isEnabled ? bg : bg.withValues(alpha: 0.55);
    final finalText = isEnabled ? textCol : textCol.withValues(alpha: 0.65);
    
    // Perforation / border color: slightly darker/lighter than fill
    final borderCol = isDark 
        ? Colors.black.withValues(alpha: 0.15) 
        : Colors.white.withValues(alpha: 0.20);

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: StampDecoratedBox(
        backgroundColor: finalBg,
        borderColor: borderCol,
        borderWidth: 1.5,
        holeRadius: 4.5,
        holeSpacing: 11.0,
        shadowElevation: isEnabled ? 2.0 : 0.0,
        shadowColor: isDark ? Colors.black.withValues(alpha: 0.4) : primary.withValues(alpha: 0.12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            splashColor: textCol.withValues(alpha: 0.12),
            highlightColor: textCol.withValues(alpha: 0.06),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(finalText),
                          ),
                        )
                      : Text(
                          label,
                          key: const ValueKey('label'),
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: finalText,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
