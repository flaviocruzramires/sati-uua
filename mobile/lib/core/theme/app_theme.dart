import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.green,
        surface: AppColors.surface,
        onSurface: AppColors.text,
      ),
      dividerColor: AppColors.divider,
      dividerTheme: const DividerThemeData(
        thickness: 2,
        color: AppColors.divider,
      ),
    );

    final textTheme = GoogleFonts.archivoTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.archivo(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.015 * 42,
      ),
      displayMedium: GoogleFonts.archivo(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.015 * 32,
      ),
      displaySmall: GoogleFonts.archivo(
        fontSize: 25,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.015 * 25,
      ),
      headlineMedium: GoogleFonts.archivo(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.015 * 20,
        color: AppColors.neutral700,
      ),
      headlineSmall: GoogleFonts.archivo(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.015 * 16,
        color: AppColors.neutral700,
      ),
      titleSmall: GoogleFonts.archivo(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.08 * 13,
        color: AppColors.neutral700,
      ),
      bodyMedium: GoogleFonts.archivo(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: AppColors.neutral700,
      ),
      bodySmall: GoogleFonts.archivo(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.neutral700,
      ),
      labelSmall: GoogleFonts.archivo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.neutral600,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.neutral700,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.neutral700),
        titleTextStyle: GoogleFonts.archivo(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.015 * 20,
          color: AppColors.neutral700,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.archivo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.neutral700,
        ),
        contentTextStyle: GoogleFonts.archivo(
          fontSize: 15,
          color: AppColors.neutral700,
          height: 1.5,
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.navy, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.red),
        ),
        labelStyle: GoogleFonts.archivo(
          fontSize: 12,
          color: AppColors.label,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.bg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          alignment: Alignment.centerLeft,
          textStyle: GoogleFonts.archivo(
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.navy),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          alignment: Alignment.centerLeft,
          textStyle: GoogleFonts.archivo(
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: GoogleFonts.archivo(
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
