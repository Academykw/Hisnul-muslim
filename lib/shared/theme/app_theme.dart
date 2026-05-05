import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryRed = Color(0xFFB71C1C); // red_700 equivalent
  static const Color primaryRedLight = Color(0xFFE53935);
  static const Color primaryRedDark = Color(0xFF7F0000);
  static const Color primaryRedSoft = Color(0xFFE36A63);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color subTextColor = Color(0xFF757575);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF5F5F5);
  static const Color darkScaffold = Color(0xFF101312);
  static const Color darkSurface = Color(0xFF171B19);
  static const Color darkSurfaceHigh = Color(0xFF202622);
  static const Color darkText = Color(0xFFE6E0D6);
  static const Color darkSubText = Color(0xFFB4ACA0);
  static const Color darkDivider = Color(0xFF303832);

  // Arabic font
  static const String defaultArabicFont = 'Uthmanic';

  static TextStyle getArabicStyle({
    required String fontFamily,
    required double fontSize,
    Color? color,
    double height = 1.8,
  }) {
    switch (fontFamily) {
      case 'Amiri':
        return GoogleFonts.amiri(
          fontSize: fontSize,
          color: color,
          height: height,
        );
      case 'Lateef':
        return GoogleFonts.lateef(
          fontSize: fontSize,
          color: color,
          height: height,
        );
      default:
        return TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          color: color,
          height: height,
        );
    }
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        primary: primaryRed,
        secondary: primaryRedLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 4,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: cardBackground,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData darkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryRed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primaryRedSoft,
      onPrimary: const Color(0xFF2E0705),
      secondary: const Color(0xFFD8B56D),
      onSecondary: const Color(0xFF2A1D05),
      surface: darkSurface,
      onSurface: darkText,
      surfaceContainerHighest: darkSurfaceHigh,
      outline: darkDivider,
      error: const Color(0xFFFFB4AB),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF151917),
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: darkSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: darkSurfaceHigh,
      ),
      scaffoldBackgroundColor: darkScaffold,
      dividerTheme: const DividerThemeData(color: darkDivider, thickness: 0.8),
      iconTheme: const IconThemeData(color: darkSubText),
      listTileTheme: const ListTileThemeData(
        iconColor: primaryRedSoft,
        textColor: darkText,
        subtitleTextStyle: TextStyle(color: darkSubText),
      ),
      textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
            bodyColor: darkText,
            displayColor: darkText,
          ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: darkSurfaceHigh,
        contentTextStyle: TextStyle(color: darkText),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurfaceHigh,
        modalBackgroundColor: darkSurfaceHigh,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryRedSoft,
        thumbColor: primaryRedSoft,
        inactiveTrackColor: darkDivider,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryRedSoft,
        foregroundColor: Color(0xFF2E0705),
      ),
    );
  }
}
