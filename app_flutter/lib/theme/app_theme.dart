import 'package:flutter/material.dart';

/// Brand tokens shared with the web prototype and icon/mascot assets.
/// Keep this file as the single source of truth for color and type so the
/// Flutter app stays visually consistent with the rest of Tabby.
class AppColors {
  static const paper = Color(0xFFF6F1E7);
  static const surface = Color(0xFFFBF7EF);
  static const ink = Color(0xFF2B231C);
  static const amber = Color(0xFFC97D3A);
  static const rust = Color(0xFF8B4A32);
  static const teal = Color(0xFF2F6E5E);
  static const coral = Color(0xFFC1483A);
  static const line = Color(0xFFE4D5BE);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.ink,
        secondary: AppColors.amber,
        surface: AppColors.surface,
        error: AppColors.coral,
      ),
      textTheme: base.textTheme.copyWith(
        // Headings and currency figures use Sora once the font is bundled
        // (see pubspec.yaml `fonts:` section, not included by default —
        // add the Sora .ttf files under assets/fonts/ and register them).
        headlineSmall: const TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleMedium: const TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyMedium: const TextStyle(color: AppColors.ink),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

/// RM currency formatting, e.g. "RM 120.00".
String formatCurrency(num amount) {
  final abs = amount.abs();
  return 'RM ${abs.toStringAsFixed(2)}';
}
