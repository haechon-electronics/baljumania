import 'package:flutter/material.dart';

/// 발주매니아 iOS 감성 테마 - 화이트 베이스 + 그린 포인트, 중장년 친화 큰 글씨
class AppColors {
  // 그린은 '포인트 색'으로만 사용 (세련된 딥그린)
  static const Color primary = Color(0xFF00875A);
  static const Color primaryLight = Color(0xFF2AA876);
  static const Color primarySoft = Color(0xFFE6F4EE);
  static const Color accent = Color(0xFFFF9500); // iOS 오렌지
  static const Color danger = Color(0xFFFF3B30); // iOS 레드
  static const Color background = Color(0xFFF2F2F7); // iOS 시스템 그레이
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF111111);
  static const Color textGrey = Color(0xFF8E8E93); // iOS 세컨더리 그레이
}

ThemeData buildAppTheme() {
  const font = 'Pretendard';
  return ThemeData(
    useMaterial3: true,
    fontFamily: font,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: Brightness.light,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,

    // iOS식 페이지 전환 (옆으로 스르륵 + 스와이프 뒤로가기)
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      },
    ),

    // 안드로이드 물결 효과 제거 → iOS처럼 은은하게
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.black.withValues(alpha: 0.04),

    // 앱바: 흰 배경 + 검정 글씨 (iOS 내비게이션바)
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.white,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: font,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      iconTheme: IconThemeData(color: AppColors.primary),
    ),

    // 카드: 그림자 없는 플랫 + 큰 라운드 (iOS 그룹 카드)
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),

    // 채움 버튼 (iOS 프라이머리 버튼)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        elevation: 0,
        textStyle: const TextStyle(
            fontFamily: font, fontSize: 19, fontWeight: FontWeight.w700),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: const TextStyle(
            fontFamily: font, fontSize: 19, fontWeight: FontWeight.w700),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    // 보조 버튼: 테두리 대신 연그린 배경 (iOS 세컨더리 버튼)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.primarySoft,
        minimumSize: const Size(double.infinity, 56),
        side: BorderSide.none,
        textStyle: const TextStyle(
            fontFamily: font, fontSize: 19, fontWeight: FontWeight.w700),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(
            fontFamily: font, fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),

    // 입력창: 연회색 채움 + 테두리 없음 (iOS 검색창 느낌)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F7),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      labelStyle: const TextStyle(
          fontFamily: font, fontSize: 17, color: AppColors.textGrey),
      hintStyle: const TextStyle(
          fontFamily: font, fontSize: 16, color: Color(0xFFB0B0B6)),
    ),

    // 큰 글씨 유지 (중장년 친화)
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
          fontFamily: font, fontSize: 18, color: AppColors.textDark),
      bodyMedium: TextStyle(
          fontFamily: font, fontSize: 17, color: AppColors.textDark),
      titleLarge: TextStyle(
          fontFamily: font,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          letterSpacing: -0.4),
      titleMedium: TextStyle(
          fontFamily: font,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          letterSpacing: -0.3),
      labelLarge: TextStyle(
          fontFamily: font, fontSize: 18, fontWeight: FontWeight.w600),
    ),

    // 하단 탭바 (iOS 탭바)
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color(0xFF9A9AA0),
      selectedLabelStyle: TextStyle(
          fontFamily: font, fontSize: 13.5, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontFamily: font, fontSize: 13),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 1,
    ),

    // 얇고 연한 구분선 (iOS)
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE5E5EA),
      thickness: 0.6,
      space: 0.6,
    ),

    listTileTheme: const ListTileThemeData(
      titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark),
      subtitleTextStyle: TextStyle(
          fontFamily: font, fontSize: 14.5, color: AppColors.textGrey),
      iconColor: AppColors.primary,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF5F5F7),
      selectedColor: AppColors.primarySoft,
      labelStyle: const TextStyle(
          fontFamily: font, fontSize: 15, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      side: BorderSide.none,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2C2C2E),
      contentTextStyle: const TextStyle(
          fontFamily: font, fontSize: 16, color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
