import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textThemeForBrightness(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark()
        : ThemeData.light();

    return base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.04,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.03,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.03,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
