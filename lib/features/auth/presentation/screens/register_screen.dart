import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stampshunter/app/theme/app_colors.dart';
import 'package:stampshunter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stampshunter/features/auth/presentation/widgets/auth_form.dart';
import 'package:stampshunter/shared/utils/stamp_snackbar.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // UX: FocusNode chain — username -> email -> displayName -> password -> confirm -> submit
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _displayNameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  late AnimationController _ctrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _headerFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ));
    _formFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    ));
    Future.microtask(() => _ctrl.forward());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _displayNameFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _register() {
    // UX: tutup keyboard sebelum validasi — mencegah layout jump saat error muncul
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      ref.read(authProvider.notifier).register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _displayNameController.text.trim().isEmpty
                ? null
                : _displayNameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated) {
        context.go('/');
      }
      if (next.error != null) {
        showStampSnackBar(
          context,
          message: next.error!,
          type: StampSnackBarType.error,
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF7F4F0);
    final primary = isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final mutedColor = const Color(0xFF888888);
    final screenH = MediaQuery.of(context).size.height;
    final isCompact = screenH < 760;

    final topPad = isCompact ? 16.0 : 36.0;
    final headingToForm = isCompact ? 16.0 : 28.0;

    final headlineFontSize = isCompact ? 28.0 : 34.0;
    final bodyFontSize = isCompact ? 11.5 : 12.5;

    final fieldGap = isCompact ? 12.0 : 20.0;
    final buttonGap = isCompact ? 20.0 : 32.0;
    final linkGap = isCompact ? 16.0 : 28.0;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      // UX: tap di area mana pun (luar field) akan tutup keyboard
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Ambient postmark decor — top-right corner
            Positioned(
              top: -40,
              right: -70,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(220, 220),
                  painter: _PostmarkPainter(color: primary),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                // UX: drag ke bawah juga menutup keyboard
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                      maxWidth: 480,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: isCompact ? 12.0 : 20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: topPad),

                            // Header — Heading & Description (staggered group 1)
                            SlideTransition(
                              position: _headerSlide,
                              child: FadeTransition(
                                opacity: _headerFade,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Buat koleksi\nbaru Anda.',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: headlineFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1A1A1A),
                                        height: 1.15,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.montserrat(
                                          fontSize: bodyFontSize,
                                          color: mutedColor,
                                          height: 1.65,
                                          letterSpacing: 0.1,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Daftar akun '),
                                          TextSpan(
                                            text: 'Stamps Hunter',
                                            style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.w700,
                                              color: primary,
                                            ),
                                          ),
                                          const TextSpan(text: ' dan buat '),
                                          TextSpan(
                                            text: 'archive',
                                            style: GoogleFonts.playfairDisplay(
                                              fontSize: bodyFontSize + 1,
                                              fontStyle: FontStyle.italic,
                                              color: primary,
                                            ),
                                          ),
                                          const TextSpan(
                                              text: ' prangko unik Anda.'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: headingToForm),

                            // Form fields & Buttons (staggered group 2)
                            SlideTransition(
                              position: _formSlide,
                              child: FadeTransition(
                                opacity: _formFade,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Username ──────────────────────────
                                    StampTextField(
                                      controller: _usernameController,
                                      label: 'Username',
                                      hintText: 'kolektor_perangko',
                                      focusNode: _usernameFocus,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: () =>
                                          FocusScope.of(context)
                                              .requestFocus(_emailFocus),
                                      // UX: username tidak perlu autocapitalize
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      textCapitalization:
                                          TextCapitalization.none,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Username tidak boleh kosong';
                                        }
                                        if (v.length < 3) {
                                          return 'Username minimal 3 karakter';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: fieldGap),

                                    // ── Email ─────────────────────────────
                                    StampTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      hintText: 'nama@email.com',
                                      keyboardType: TextInputType.emailAddress,
                                      focusNode: _emailFocus,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: () =>
                                          FocusScope.of(context)
                                              .requestFocus(_displayNameFocus),
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      textCapitalization:
                                          TextCapitalization.none,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Email tidak boleh kosong';
                                        }
                                        if (!v.contains('@')) {
                                          return 'Format email tidak valid';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: fieldGap),

                                    // ── Display Name (opsional) ────────────
                                    StampTextField(
                                      controller: _displayNameController,
                                      label: 'Nama Tampilan (opsional)',
                                      hintText: 'Nama Lengkap Anda',
                                      focusNode: _displayNameFocus,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: () =>
                                          FocusScope.of(context)
                                              .requestFocus(_passwordFocus),
                                      // UX: nama bisa diawali huruf kapital
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                    SizedBox(height: fieldGap),

                                    // ── Password ──────────────────────────
                                    StampTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hintText: '••••••••',
                                      obscureText: _obscurePassword,
                                      focusNode: _passwordFocus,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: () =>
                                          FocusScope.of(context).requestFocus(
                                              _confirmPasswordFocus),
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          setState(() => _obscurePassword =
                                              !_obscurePassword);
                                        },
                                        padding: const EdgeInsets.all(12),
                                        constraints: const BoxConstraints(
                                            minWidth: 44, minHeight: 44),
                                        splashRadius: 20,
                                        icon: AnimatedSwitcher(
                                          duration: const Duration(
                                              milliseconds: 180),
                                          child: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons
                                                    .visibility_off_outlined,
                                            key: ValueKey(_obscurePassword),
                                            size: 18,
                                            color: mutedColor,
                                          ),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Password tidak boleh kosong';
                                        }
                                        if (v.length < 8) {
                                          return 'Password minimal 8 karakter';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: fieldGap),

                                    // ── Konfirmasi Password ────────────────
                                    StampTextField(
                                      controller: _confirmPasswordController,
                                      label: 'Konfirmasi Password',
                                      hintText: '••••••••',
                                      obscureText: _obscureConfirmPassword,
                                      focusNode: _confirmPasswordFocus,
                                      // UX: Done langsung trigger submit
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: _register,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          setState(() =>
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword);
                                        },
                                        padding: const EdgeInsets.all(12),
                                        constraints: const BoxConstraints(
                                            minWidth: 44, minHeight: 44),
                                        splashRadius: 20,
                                        icon: AnimatedSwitcher(
                                          duration: const Duration(
                                              milliseconds: 180),
                                          child: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_outlined
                                                : Icons
                                                    .visibility_off_outlined,
                                            key: ValueKey(
                                                _obscureConfirmPassword),
                                            size: 18,
                                            color: mutedColor,
                                          ),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v != _passwordController.text) {
                                          return 'Password tidak cocok';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: buttonGap),

                                    // ── Register Button ────────────────────
                                    StampButton(
                                      label: 'Daftar',
                                      isLoading: authState.isLoading,
                                      onPressed: _register,
                                    ),
                                    SizedBox(height: linkGap),

                                    // ── Login link ─────────────────────────
                                    Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Sudah punya akun?',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 13,
                                              color: mutedColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          // UX: InkWell dengan padding jelas utk touch target 48dp
                                          InkWell(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              context.go('/login');
                                            },
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            splashColor: primary
                                                .withValues(alpha: 0.12),
                                            highlightColor: primary
                                                .withValues(alpha: 0.06),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 16),
                                              child: Text(
                                                'Masuk',
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: primary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isCompact ? 12.0 : 24.0),
                          ],
                        ),
                      ),
                    ),
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

// ── Postmark Painter ──────────────────────────────────────────────────────────

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

    // Horizontal band lines (classic postmark)
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
