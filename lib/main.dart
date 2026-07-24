import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stampshunter/config/supabase_config.dart';
import 'package:stampshunter/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Eager-init SharedPreferences agar onboarding provider sinkron (no loading flash di router)
  final prefs = await SharedPreferences.getInstance();

  try {
    if (SupabaseConfig.url.isNotEmpty &&
        !SupabaseConfig.url.contains('your-project-id')) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
      );
    }
  } catch (e) {
    debugPrint('Gagal menginisialisasi Supabase: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const StampsHunterApp(),
    ),
  );
}
