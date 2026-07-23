import 'package:flutter/material.dart';

/// 발주매니아 딥 그린 테마 - 중장년 친화 큰 글씨
class AppColors {
  static const Color primary = Color(0xFF1B5E20); // 딥 포레스트 그린
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color primarySoft = Color(0xFFE8F5E9);
  static const Color accent = Color(0xFFFF8F00); // 경고/포인트 주황
  static const Color danger = Color(0xFFD32F2F);
  static const Color background = Color(0xFFF7F9F7);
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF1C1C1C);
  static const Color textGrey = Color(0xFF616161);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 1.5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 56),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(fontSize: 17, color: AppColors.textGrey),
      hintStyle: const TextStyle(fontSize: 16, color: Colors.black38),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 18, color: AppColors.textDark),
      bodyMedium: TextStyle(fontSize: 17, color: AppColors.textDark),
      titleLarge: TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
      titleMedium: TextStyle(
          fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textDark),
      labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textGrey,
      selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontSize: 13),
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE0E0E0)),
  );
}
