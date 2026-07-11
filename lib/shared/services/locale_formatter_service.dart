import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Locale-aware formatters for date, time, and currency.
/// Obtained from [localeFormatterProvider] — never instantiated directly in UI.
class LocaleFormatterService {
  const LocaleFormatterService(this._locale);

  final Locale _locale;

  /// Date format: DD/MM/YYYY for FR/AR, YYYY-MM-DD for EN.
  String formatDate(DateTime date) {
    final String pattern = _locale.languageCode == 'en'
        ? 'yyyy-MM-dd'
        : 'dd/MM/yyyy';
    return DateFormat(pattern).format(date);
  }

  /// Time format: 24h for all locales.
  String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Currency format: TND with 3 decimal places.
  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: _locale.toString(),
      symbol: 'TND',
      decimalDigits: 3,
    ).format(amount);
  }
}
