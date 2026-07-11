import 'package:docentral/shared/design_system/app_colors.dart';
import 'package:docentral/shared/design_system/app_typography.dart';
import 'package:flutter/material.dart';

/// Central Material 3 theme. All screens must derive styling from here
/// rather than hardcoding colors, text styles, or spacing.
abstract class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seed),
    textTheme: AppTypography.textTheme,
  );
}
