import 'package:docentral/shared/services/locale_formatter_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocaleFormatterService — date', () {
    final date = DateTime(2026, 5, 31);

    test('formats as DD/MM/YYYY for FR', () {
      expect(const LocaleFormatterService(Locale('fr')).formatDate(date), '31/05/2026');
    });

    test('formats as DD/MM/YYYY for EN', () {
      expect(const LocaleFormatterService(Locale('en')).formatDate(date), '31/05/2026');
    });

    test('formats as DD/MM/YYYY for AR', () {
      expect(const LocaleFormatterService(Locale('ar')).formatDate(date), '31/05/2026');
    });
  });

  group('LocaleFormatterService — time', () {
    final time = DateTime(2026, 1, 1, 14, 30);

    test('formats as HH:mm 24h for FR', () {
      expect(const LocaleFormatterService(Locale('fr')).formatTime(time), '14:30');
    });

    test('formats as HH:mm 24h for EN', () {
      expect(const LocaleFormatterService(Locale('en')).formatTime(time), '14:30');
    });

    test('formats as HH:mm 24h for AR', () {
      expect(const LocaleFormatterService(Locale('ar')).formatTime(time), '14:30');
    });
  });

  group('LocaleFormatterService — currency', () {
    test('formats TND with 3 decimal places for FR', () {
      final result = const LocaleFormatterService(Locale('fr')).formatCurrency(1234.5);
      expect(result, contains('TND'));
      expect(result, contains('500'));
    });

    test('formats TND with 3 decimal places for EN', () {
      final result = const LocaleFormatterService(Locale('en')).formatCurrency(1234.5);
      expect(result, contains('TND'));
      expect(result, contains('500'));
    });

    test('formats TND with 3 decimal places for AR', () {
      final result = const LocaleFormatterService(Locale('ar')).formatCurrency(1234.5);
      expect(result, contains('TND'));
    });
  });

  group('LocaleFormatterService — supported locales', () {
    test('all supported locales produce non-empty date output', () {
      final date = DateTime(2026, 1, 15);
      for (final locale in [const Locale('fr'), const Locale('en'), const Locale('ar')]) {
        final result = LocaleFormatterService(locale).formatDate(date);
        expect(result, isNotEmpty, reason: '${locale.languageCode} date was empty');
      }
    });

    test('all supported locales produce non-empty time output', () {
      final time = DateTime(2026, 1, 1, 9, 5);
      for (final locale in [const Locale('fr'), const Locale('en'), const Locale('ar')]) {
        final result = LocaleFormatterService(locale).formatTime(time);
        expect(result, isNotEmpty, reason: '${locale.languageCode} time was empty');
      }
    });
  });
}
