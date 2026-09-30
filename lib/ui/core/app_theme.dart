import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Handcrafted Warm Editorial Palette (matching Welcome Screen)
  static const primary = Color(0xFFC2410C); // Warm Terracotta / Rich Clay
  static const primaryDark = Color(0xFF9A3412); // Deep Burnt Sienna
  static const secondary = Color(0xFF047857); // Calm Botanical Sage / Forest Green
  static const accent = Color(0xFFD97706); // Warm Amber / Honey Gold
  static const background = Color(0xFFFAF7F2); // Warm Oatmeal / Rice Paper / Linen
  static const cardBackground = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF3ECE0); // Warm Cream Paper
  static const borderLight = Color(0xFFE8DFD3); // Subtle Warm Border
  static const borderDark = Color(0xFF332F2B);
  
  static const textPrimary = Color(0xFF2D2620); // Deep Warm Espresso
  static const textSecondary = Color(0xFF796F65); // Muted Sepia Taupe
  
  static const success = Color(0xFF059669); // Forest Sage Green
  static const warning = Color(0xFFD97706); // Warm Ochre / Amber
  static const error = Color(0xFFDC2626); // Warm Terracotta Red

  // Harmonized Earthy & Botanical Subject Colors
  static const subjectColors = [
    Color(0xFFC2410C), // Terracotta
    Color(0xFF047857), // Sage Green
    Color(0xFFD97706), // Warm Amber
    Color(0xFF2563EB), // Slate Royal Blue
    Color(0xFF7C3AED), // Soft Lavender Violet
    Color(0xFFB45309), // Ochre Amber
    Color(0xFF0D9488), // Deep Sea Pine
    Color(0xFFBE185D), // Rose Clay
    Color(0xFF475569), // Warm Charcoal Slate
    Color(0xFF4D7C0F), // Olive Moss
  ];

  // Realistic Dark theme: OLED Midnight Black, Electric Neon Blue, and Deep Royal Purple
  static const darkBackground = Color(0xFF030712); // Pure OLED Midnight Black
  static const darkCard = Color(0xFF0F172A); // Deep Slate / Midnight Black
  static const darkSurface = Color(0xFF1E1B4B); // Deep Royal Indigo / Purple Surface
  static const darkSurfaceVariant = Color(0xFF1E293B);
  static const darkTextPrimary = Color(0xFFF8FAFC); // Crisp Bright White
  static const darkTextSecondary = Color(0xFF94A3B8); // Muted Cool Slate
  static const darkBorder = Color(0xFF1E293B); // Dark Slate Border
  static const darkBorderAccent = Color(0xFF38BDF8); // Electric Blue Accent

  // Dark Theme Accents
  static const darkPrimary = Color(0xFF38BDF8); // Electric Sky Blue
  static const darkSecondary = Color(0xFF8B5CF6); // Royal Violet Purple
  static const darkAccent = Color(0xFFA855F7); // Electric Neon Purple
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.cardBackground,
        surfaceContainerHighest: AppColors.surfaceVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.lora(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderLight, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primary.withAlpha(100),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary.withAlpha(180),
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        tertiary: AppColors.darkAccent,
        surface: AppColors.darkCard,
        surfaceContainerHighest: AppColors.darkSurface,
        onPrimary: Color(0xFF030712),
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: GoogleFonts.lora(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: const Color(0xFF030712),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0B132B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1E293B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1E293B), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF090D16),
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: Color(0xFF64748B),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: const Color(0xFF030712),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
