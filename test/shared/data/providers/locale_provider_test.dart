import 'package:docentral/shared/data/providers/locale_provider.dart';
import 'package:docentral/shared/data/providers/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'app_locale';

Future<ProviderContainer> _makeContainer({String? savedLocale}) async {
  SharedPreferences.setMockInitialValues(
    savedLocale != null ? {_localeKey: savedLocale} : {},
  );
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLocale provider', () {
    test('defaults to French when no locale is saved', () async {
      final container = await _makeContainer();
      addTearDown(container.dispose);
      expect(container.read(appLocaleProvider), const Locale('fr'));
    });

    test('restores saved locale from shared preferences', () async {
      final container = await _makeContainer(savedLocale: 'ar');
      addTearDown(container.dispose);
      expect(container.read(appLocaleProvider), const Locale('ar'));
    });

    test('falls back to French for unknown locale code', () async {
      final container = await _makeContainer(savedLocale: 'zz');
      addTearDown(container.dispose);
      expect(container.read(appLocaleProvider), const Locale('fr'));
    });

    test('setLocale updates state and persists to prefs', () async {
      final container = await _makeContainer();
      addTearDown(container.dispose);

      final prefs = container.read(sharedPreferencesProvider);
      container.read(appLocaleProvider.notifier).setLocale(const Locale('en'));

      expect(container.read(appLocaleProvider), const Locale('en'));
      expect(prefs.getString(_localeKey), 'en');
    });
  });
}
