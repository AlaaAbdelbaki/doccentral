import 'package:docentral/app.dart';
import 'package:docentral/shared/data/providers/shared_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('DocCentralApp boots to the calendar destination', (
    WidgetTester tester,
  ) async {
    // Seed an explicit locale so the assertion isn't coupled to the app's
    // default language (French) — see locale_provider.dart.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_locale': 'en',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const DocCentralApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The label appears both as nav destination text and as the page body,
    // and which nav layout renders depends on the test surface width.
    expect(find.text("Today's Calendar"), findsWidgets);
  });
}
