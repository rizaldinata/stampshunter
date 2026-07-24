import 'package:shared_preferences/shared_preferences.dart';

/// Abstraksi akses local storage untuk status onboarding.
/// Kunci: 'has_seen_onboarding' (bool)
class OnboardingLocalDatasource {
  final SharedPreferences _prefs;

  const OnboardingLocalDatasource(this._prefs);

  static const _key = 'has_seen_onboarding';

  /// Sinkron — aman dipanggil dari provider biasa (non-Future).
  bool hasSeenOnboarding() => _prefs.getBool(_key) ?? false;

  Future<void> markOnboardingSeen() async {
    await _prefs.setBool(_key, true);
  }

  /// Untuk keperluan testing / reset manual.
  Future<void> resetOnboarding() async {
    await _prefs.remove(_key);
  }
}
