import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stampshunter/app/theme/app_colors.dart';
import 'package:stampshunter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stampshunter/features/auth/presentation/widgets/auth_form.dart';
import 'package:stampshunter/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:stampshunter/shared/utils/stamp_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // UX: FocusNode chain — email -> password -> submit
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late AnimationController _ctrl;
  late Animation<double> _logoFade;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _contentFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
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
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _login() {
    // UX: tutup keyboard sebelum validasi — mencegah layout jump saat error muncul
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.isAuthenticated) context.go('/');
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
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Form(
                        key: _formKey,
                        child: Builder(
                          builder: (context) {
                            final screenH =
                                MediaQuery.of(context).size.height;
                            final isSmall = screenH < 680;

                            final topPad = isSmall ? 40.0 : 60.0;
                            final logoToHeading = isSmall ? 24.0 : 36.0;
                            final headingToForm = isSmall ? 28.0 : 40.0;
                            final bottomPad = isSmall ? 24.0 : 48.0;
                            final logoSize = isSmall ? 56.0 : 64.0;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: topPad),

                                // ── Logo ──────────────────────────────
                                FadeTransition(
                                  opacity: _logoFade,
                                  child: GestureDetector(
                                    onLongPress: () async {
                                      HapticFeedback.heavyImpact();
                                      // Reset onboarding state in SharedPreferences
                                      await ref
                                          .read(onboardingLocalDatasourceProvider)
                                          .resetOnboarding();
                                      // Reset the StateProvider state to notify router
                                      ref
                                          .read(hasSeenOnboardingProvider.notifier)
                                          .state = false;
                                      if (context.mounted) {
                                        showStampSnackBar(
                                          context,
                                          message:
                                              'Reset onboarding sukses! Mengalihkan...',
                                          type: StampSnackBarType.success,
                                        );
                                        context.go('/onboarding');
                                      }
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.asset(
                                        'assets/images/stampshunter.png',
                                        width: logoSize,
                                        height: logoSize,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: logoToHeading),

                                // ── Heading ───────────────────────────
                                SlideTransition(
                                  position: _contentSlide,
                                  child: FadeTransition(
                                    opacity: _contentFade,
                                    child: _Heading(
                                        isDark: isDark, isSmall: isSmall),
                                  ),
                                ),

                                SizedBox(height: headingToForm),

                                // ── Fields ────────────────────────────
                                SlideTransition(
                                  position: _contentSlide,
                                  child: FadeTransition(
                                    opacity: _contentFade,
                                    child: _Fields(
                                      isDark: isDark,
                                      authState: authState,
                                      emailController: _emailController,
                                      passwordController: _passwordController,
                                      obscurePassword: _obscurePassword,
                                      emailFocus: _emailFocus,
                                      passwordFocus: _passwordFocus,
                                      onTogglePassword: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _obscurePassword =
                                            !_obscurePassword);
                                      },
                                      onLogin: _login,
                                      onRegister: () {
                                        HapticFeedback.lightImpact();
                                        context.go('/register');
                                      },
                                    ),
                                  ),
                                ),

                                SizedBox(height: bottomPad),
                              ],
                            );
                          },
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

// ── Heading ───────────────────────────────────────────────────────────────────

class _Heading extends StatelessWidget {
  final bool isDark;
  final bool isSmall;
  const _Heading({required this.isDark, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final mutedColor = const Color(0xFF888888);
    final accentColor =
        isDark ? AppColors.primaryDarkTheme : AppColors.primary;

    final headlineFontSize = isSmall ? 30.0 : 38.0;
    final bodyFontSize = isSmall ? 12.0 : 13.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Koleksi mu\nmenunggumu.',
          style: GoogleFonts.playfairDisplay(
            fontSize: headlineFontSize,
            fontWeight: FontWeight.w700,
            color: textColor,
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
              const TextSpan(text: 'Masuk dan lanjutkan membuat '),
              TextSpan(
                text: 'stamp',
                style: GoogleFonts.playfairDisplay(
                  fontSize: bodyFontSize + 1,
                  fontStyle: FontStyle.italic,
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: ' unik\ndari momen terbaik Anda.'),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Fields & Actions ──────────────────────────────────────────────────────────

class _Fields extends StatelessWidget {
  final bool isDark;
  final AuthState authState;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _Fields({
    required this.isDark,
    required this.authState,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.emailFocus,
    required this.passwordFocus,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final primary =
        isDark ? AppColors.primaryDarkTheme : AppColors.primary;
    final mutedColor = const Color(0xFF777777);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Email ─────────────────────────────────────
        StampTextField(
          controller: emailController,
          label: 'Email',
          hintText: 'nama@email.com',
          keyboardType: TextInputType.emailAddress,
          focusNode: emailFocus,
          // UX: Next membawa fokus ke field berikutnya
          textInputAction: TextInputAction.next,
          onFieldSubmitted: () =>
              FocusScope.of(context).requestFocus(passwordFocus),
          // UX: email tidak perlu autocorrect/autocapitalize
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
            if (!v.contains('@')) return 'Format email tidak valid';
            return null;
          },
        ),

        const SizedBox(height: 14),

        // ── Password ───────────────────────────────────
        StampTextField(
          controller: passwordController,
          label: 'Kata Sandi',
          hintText: '••••••••',
          obscureText: obscurePassword,
          focusNode: passwordFocus,
          // UX: Done langsung trigger submit
          textInputAction: TextInputAction.done,
          onFieldSubmitted: onLogin,
          // UX: password tidak perlu autocorrect/suggestions
          autocorrect: false,
          enableSuggestions: false,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
            return null;
          },
          suffixIcon: IconButton(
            onPressed: onTogglePassword,
            // UX: minimum touch target 48x48dp (Material guideline)
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            splashRadius: 20,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                key: ValueKey(obscurePassword),
                size: 18,
                color: mutedColor,
              ),
            ),
          ),
        ),

        // ── Lupa sandi ────────────────────────────────
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            // UX: minimum touch target 48dp height sesuai Material guideline
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
              splashFactory: NoSplash.splashFactory,
            ),
            child: Text(
              'Lupa kata sandi?',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: mutedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Tombol Masuk ─────────────────────────────
        StampButton(
          label: 'Buka Koleksi',
          isLoading: authState.isLoading,
          onPressed: onLogin,
        ),

        const SizedBox(height: 28),

        // ── Divider ──────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.07),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'atau',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: mutedColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.07),
                thickness: 1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ── Register link ─────────────────────────────
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Belum punya akun?',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: mutedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            // UX: InkWell dengan padding jelas utk touch target 48dp
            InkWell(
              onTap: onRegister,
              borderRadius: BorderRadius.circular(8),
              splashColor: primary.withValues(alpha: 0.12),
              highlightColor: primary.withValues(alpha: 0.06),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Text(
                  'Mulai Berkreasi',
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
      ],
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
