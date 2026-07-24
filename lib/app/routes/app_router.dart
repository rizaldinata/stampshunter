import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampshunter/features/auth/presentation/providers/auth_provider.dart';
import 'package:stampshunter/features/auth/presentation/screens/login_screen.dart';
import 'package:stampshunter/features/auth/presentation/screens/register_screen.dart';
import 'package:stampshunter/features/auth/presentation/screens/splash_screen.dart';
import 'package:stampshunter/features/feed/presentation/screens/feed_screen.dart';
import 'package:stampshunter/features/feed/presentation/screens/stamp_detail_screen.dart';
import 'package:stampshunter/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:stampshunter/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:stampshunter/features/profile/presentation/screens/profile_screen.dart';
import 'package:stampshunter/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:stampshunter/features/stamp/presentation/screens/stamp_editor_screen.dart';
import 'package:stampshunter/features/camera/presentation/screens/camera_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // ── 0. App sedang init (restore session) → tahan di /splash ──────────
      // Jangan buat keputusan redirect sampai AuthNotifier._init() selesai.
      if (authState.isInitializing) {
        return loc == '/splash' ? null : '/splash';
      }

      final isLoggedIn = authState.isAuthenticated;
      final isOnboarding = loc == '/onboarding';
      final isAuthRoute = loc == '/login' || loc == '/register';
      final isSplash = loc == '/splash';

      // ── 1. Init selesai, keluar dari splash → tentukan tujuan ─────────────
      if (isSplash) {
        if (!hasSeenOnboarding) return '/onboarding';
        if (!isLoggedIn) return '/login';
        return '/'; // Sudah login → langsung ke feed
      }

      // ── 2. Belum pernah lihat onboarding → wajib ke /onboarding ──────────
      if (!hasSeenOnboarding && !isOnboarding) return '/onboarding';

      // ── 3. Sudah onboarding, belum login, bukan di auth/onboarding → /login
      if (hasSeenOnboarding && !isLoggedIn && !isAuthRoute && !isOnboarding) {
        return '/login';
      }

      // ── 4. Sudah login, mencoba ke auth/onboarding/splash → /feed ─────────
      if (isLoggedIn && (isAuthRoute || isOnboarding || isSplash)) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/stamp-editor',
        builder: (context, state) {
          final imagePath = state.extra as String?;
          return StampEditorScreen(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) => ProfileScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/stamp/:stampId',
        builder: (context, state) => StampDetailScreen(
          stampId: state.pathParameters['stampId']!,
        ),
      ),
    ],
  );
});
