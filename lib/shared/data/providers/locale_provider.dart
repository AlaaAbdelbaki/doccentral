import 'package:docentral/shared/data/providers/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

const _localeKey = 'app_locale';

/// Supported locales in display order.
const supportedLocales = [Locale('fr'), Locale('en'), Locale('ar')];

const _defaultLocale = Locale('fr');

@riverpod
class AppLocale extends _$AppLocale {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final code = prefs.getString(_localeKey);
    if (code == null) return _defaultLocale;
    return supportedLocales.firstWhere(
      (l) => l.languageCode == code,
      orElse: () => _defaultLocale,
    );
  }

  void setLocale(Locale locale) {
    ref
        .read(sharedPreferencesProvider)
        .setString(_localeKey, locale.languageCode);
    state = locale;
  }
}
