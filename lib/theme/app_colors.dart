import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3B5BDB);
  static const Color primaryDark = Color(0xFF2B3EAD);
  static const Color primarySoft = Color(0xFFEAF0FF);
  static const Color accent = Color(0xFF7C4DFF);
  static const Color accentSoft = Color(0xFFF1EBFF);
  static const Color deepNavy = Color(0xFF101A32);
  static const Color deepNavySoft = Color(0xFF1B2A45);
  static const Color lightBackground = Color(0xFFF3F6FB);
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111C2F);
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteSoft = Color(0xFFF8FAFC);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color lavender = Color(0xFF8B5CF6);

  static const List<Color> premiumGradient = [
    Color(0xFF2F5BFF),
    Color(0xFF5C6CFF),
    Color(0xFF8B5CF6),
  ];

  static LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF11264D),
          Color(0xFF2247C6),
          Color(0xFF6D4DDE),
        ],
      );
}
