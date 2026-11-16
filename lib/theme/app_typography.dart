import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textThemeForBrightness(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark()
        : ThemeData.light();

    return base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.05,
        height: 1.1,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        height: 1.15,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04,
        height: 1.15,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.03,
        height: 1.2,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
        height: 1.2,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
        height: 1.25,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.01,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
