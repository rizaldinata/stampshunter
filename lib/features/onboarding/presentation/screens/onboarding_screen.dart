import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stampshunter/features/auth/presentation/widgets/auth_form.dart';
import 'package:stampshunter/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:stampshunter/features/onboarding/presentation/widgets/onboarding_page_item.dart';
import 'package:stampshunter/features/onboarding/presentation/widgets/postmark_page_indicator.dart';

// ─── Data konten slide ────────────────────────────────────────────────────────

class _SlideData {
  final String title;
  final String description;
  final CustomPainter painter;

  const _SlideData({
    required this.title,
    required this.description,
    required this.painter,
  });
}

final _slides = [
  _SlideData(
    title: 'Jelajahi Jejak Sejarah',
    description:
        'Temukan prangko-prangko vintage nan langka dari berbagai era dan penjuru dunia.',
    painter: const HuntIllustrationPainter(),
  ),
  _SlideData(
    title: 'Digitalisasi Koleksi Anda',
    description:
        'Catat, kelompokkan, dan tata album prangko fisik Anda ke dalam arsip digital pribadi yang aman.',
    painter: const ArchiveIllustrationPainter(),
  ),
  _SlideData(
    title: 'Hubungkan Antar Kolektor',
    description:
        'Bagikan keindahan koleksi prangko Anda dan berjejaring dengan komunitas kolektor global.',
    painter: const ShowcaseIllustrationPainter(),
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  int _currentPage = 0;
  double _pageOffset = 0.0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    _pageController.addListener(_onPageScroll);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _fadeCtrl,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    Future.microtask(() => _fadeCtrl.forward());
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    final page = _pageController.page ?? 0.0;
    setState(() {
      _pageOffset = page;
      _currentPage = page.round();
    });
  }

  // ── Selesai onboarding ─────────────────────────────────────────────────────
  Future<void> _finish() async {
    HapticFeedback.lightImpact();
    await ref.read(onboardingNotifierProvider.notifier).markSeen();
    if (mounted) context.go('/login');
  }

  // ── Navigasi ke halaman berikutnya ─────────────────────────────────────────
  void _nextPage() {
    HapticFeedback.lightImpact();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Navigasi ke halaman sebelumnya ─────────────────────────────────────────
  void _previousPage() {
    HapticFeedback.lightImpact();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // "Postal Noir" palette — sepia warm paper (screen onboarding = light only per design)
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF7F3ED);
    final primaryColor =
        isDark ? const Color(0xFFFFB300) : const Color(0xFF8B4513);
    final mutedColor =
        isDark ? const Color(0xFF888888) : const Color(0xFF9E9585);

    final screenH = MediaQuery.of(context).size.height;
    final isSmall = screenH < 680;
    final bottomPad = isSmall ? 24.0 : 40.0;

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Stack(
            children: [
              // ── Dekorasi ambient postmark ────────────────────────────────
              Positioned(
                top: -50,
                right: -80,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.07,
                    child: CustomPaint(
                      size: const Size(260, 260),
                      painter: _AmbientPostmarkPainter(color: primaryColor),
                    ),
                  ),
                ),
              ),

              // ── PageView ─────────────────────────────────────────────────
              Column(
                children: [
                  Expanded(
                    child: SafeArea(
                      bottom: false,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (page) {
                          HapticFeedback.selectionClick();
                        },
                        itemCount: _slides.length,
                        itemBuilder: (context, index) {
                          final slide = _slides[index];
                          // Hitung parallax offset relatif ke page ini
                          final page = (_pageController.hasClients &&
                                  _pageController.position.hasPixels)
                              ? _pageController.page
                              : null;
                          final parallax = page != null ? (page - index) : 0.0;
                          return OnboardingPageItem(
                            title: slide.title,
                            description: slide.description,
                            illustrationPainter: slide.painter,
                            parallaxOffset: parallax,
                          );
                        },
                      ),
                    ),
                  ),

                  SafeArea(
                    top: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(28, 16, 28, bottomPad),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Indikator halaman (sliding smooth)
                              PostmarkPageIndicator(
                                count: _slides.length,
                                pageOffset: _pageOffset,
                                activeColor: primaryColor,
                              ),
                              SizedBox(height: isSmall ? 16 : 24),

                              // Tombol navigasi
                              _buildBottomButtons(mutedColor: mutedColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tombol Navigasi: Kembali (kiri) + Lanjut/Mulai (kanan) ────────────────
  Widget _buildBottomButtons({required Color mutedColor}) {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == _slides.length - 1;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isFirst
          ? SizedBox(
              key: const ValueKey('first_page_btn'),
              width: double.infinity,
              child: StampButton(
                label: 'Lanjut →',
                onPressed: _nextPage,
              ),
            )
          : Row(
              key: const ValueKey('nav_buttons_row'),
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Kembali
                InkWell(
                  onTap: _previousPage,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Text(
                      '← Kembali',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: mutedColor,
                      ),
                    ),
                  ),
                ),

                // Tombol Lanjut / Mulai Sekarang
                SizedBox(
                  width: isLast ? 170 : 140,
                  child: StampButton(
                    label: isLast ? 'Mulai Sekarang' : 'Lanjut →',
                    onPressed: isLast ? _finish : _nextPage,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Ambient postmark painter (dekorasi latar) ────────────────────────────────

class _AmbientPostmarkPainter extends CustomPainter {
  final Color color;
  const _AmbientPostmarkPainter({required this.color});


  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final r in [size.width * 0.45, size.width * 0.38, size.width * 0.30]) {
      canvas.drawCircle(center, r, paint);
    }
    for (int i = 0; i < 4; i++) {
      final y = center.dy - 18 + i * 12.0;
      canvas.drawLine(
        Offset(center.dx - size.width * 0.3, y),
        Offset(center.dx + size.width * 0.3, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
