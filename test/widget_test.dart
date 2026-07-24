import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stampshunter/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stampshunter/features/onboarding/presentation/providers/onboarding_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const StampsHunterApp(),
      ),
    );
    expect(find.text('Jelajahi Jejak Sejarah'), findsOneWidget);
  });
}
