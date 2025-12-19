import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFea2a33);
  static const Color primaryDark = Color(0xFFc91a22);
  static const Color primaryHover = Color(0xFFb91c1c);

  static const Color backgroundLight = Color(0xFFf8f6f6);
  static const Color backgroundDark = Color(
    0xFF121212,
  ); // Professional neutral dark

  static const Color surfaceLight = Color(0xFFffffff);
  static const Color surfaceDark = Color(
    0xFF1E1E1E,
  ); // Standard material surface

  static const Color textMain = Color(0xFF1b0e0e);
  static const Color textSub = Color(0xFF635050);

  static const Color borderLight = Color(0xFFe8e0e0);
  static const Color borderDark = Color(0xFF2C2C2C); // Neutral border

  static const Color success = Color(0xFF10b981);
}

class AppTextStyles {
  // Headings
  static TextStyle get display => GoogleFonts.beVietnamPro();
  static TextStyle get body => GoogleFonts.notoSans();
  static TextStyle get outfit => GoogleFonts.outfit();
  static TextStyle get inter => GoogleFonts.inter();
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textMain,
      ),
      fontFamily: GoogleFonts.notoSans().fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
        displayMedium: AppTextStyles.display.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
        bodyLarge: AppTextStyles.body.copyWith(color: AppColors.textMain),
        bodyMedium: AppTextStyles.body.copyWith(color: AppColors.textMain),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.backgroundDark, // Was background
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      fontFamily: GoogleFonts.notoSans().fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: AppTextStyles.display.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: AppTextStyles.body.copyWith(color: Colors.white),
        bodyMedium: AppTextStyles.body.copyWith(color: Colors.white),
      ),
    );
  }
}
