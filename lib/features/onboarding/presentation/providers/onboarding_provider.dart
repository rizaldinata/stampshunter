import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stampshunter/features/onboarding/data/datasource/onboarding_local_datasource.dart';

// ─── SharedPreferences Provider ──────────────────────────────────────────────
// Di-override di main.dart dengan instance yang sudah di-await.
// Ini agar semua downstream provider bisa sinkron (tidak ada loading flash di router).

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider harus di-override di main() '
    'dengan ProviderScope(overrides: [...])',
  );
});

// ─── Datasource Provider ─────────────────────────────────────────────────────

final onboardingLocalDatasourceProvider =
    Provider<OnboardingLocalDatasource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingLocalDatasource(prefs);
});

// ─── State Provider ───────────────────────────────────────────────────────────
// Sinkron — cukup Provider<bool> karena SharedPreferences sudah di-init di main.

final hasSeenOnboardingProvider = StateProvider<bool>((ref) {
  return ref.watch(onboardingLocalDatasourceProvider).hasSeenOnboarding();
});

// ─── Notifier ─────────────────────────────────────────────────────────────────

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(onboardingLocalDatasourceProvider).hasSeenOnboarding();
  }

  /// Dipanggil saat pengguna selesai/skip onboarding.
  Future<void> markSeen() async {
    await ref
        .read(onboardingLocalDatasourceProvider)
        .markOnboardingSeen();
    state = true;
    // Invalidate StateProvider agar router juga bereaksi
    ref.invalidate(hasSeenOnboardingProvider);
  }
}

final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
