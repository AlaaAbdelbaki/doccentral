import 'package:docentral/shared/design_system/app_colors.dart';
import 'package:docentral/shared/design_system/app_theme.dart';
import 'package:docentral/shared/design_system/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme uses Material 3 with the seeded color scheme', () {
    final ColorScheme expected = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
    );

    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.light.colorScheme.primary, expected.primary);
    expect(AppTheme.light.colorScheme.brightness, Brightness.light);
  });

  test('light theme uses the app type scale', () {
    expect(
      AppTheme.light.textTheme.bodyLarge?.fontSize,
      AppTypography.textTheme.bodyLarge?.fontSize,
    );
    expect(
      AppTheme.light.textTheme.titleLarge?.fontWeight,
      AppTypography.textTheme.titleLarge?.fontWeight,
    );
  });
}
