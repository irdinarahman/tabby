import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Brand tokens shared with the web prototype and the icon/mascot assets.
class AppColors {
  static const paper = Color(0xFFF6F1E7);
  static const surface = Color(0xFFFBF7EF);
  static const ink = Color(0xFF2B231C);
  static const muted = Color(0xFF6B5F55);
  static const amber = Color(0xFFC97D3A);
  static const rust = Color(0xFF8B4A32);
  static const teal = Color(0xFF2F6E5E);
  static const coral = Color(0xFFC1483A);
  static const line = Color(0xFFE4D5BE);
  static const amberTint = Color(0x26C97D3A);
  static const tealTint = Color(0x242F6E5E);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.ink,
        onPrimary: AppColors.surface,
        secondary: AppColors.amber,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.coral,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.rust, width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.amberTint,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: AppColors.surface, fontFamily: 'Inter'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.surface,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.rust,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}

final NumberFormat _money = NumberFormat('#,##0.00');

/// RM currency formatting, e.g. "RM 1,250.00". Always shows the absolute
/// value; callers decide how to show the sign.
String formatCurrency(num amount) => 'RM ${_money.format(amount.abs())}';

const _monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "12 Sep 2026"
String formatDate(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';

/// "12 September 2026"
String formatDateLong(DateTime d) => '${d.day} ${_monthsLong[d.month - 1]} ${d.year}';

String plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';
