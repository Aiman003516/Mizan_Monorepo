import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // ═══════════════════════════════════════════════════════════
  // ☀️ LIGHT THEME — Emerald Whisper
  // ═══════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    const colors = AppColors.light;

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,

      // ── Color Scheme ──
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: Brightness.light,
        primary: colors.primary,
        secondary: colors.secondary,
        tertiary: colors.accent,
        surface: colors.background,
        error: colors.error,
      ),

      scaffoldBackgroundColor: colors.background,

      // ── App Bar ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        titleTextStyle: TextStyle(
          color: colors.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.cardSurface,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border, width: 0.5),
        ),
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.primary,
        labelStyle: TextStyle(color: colors.onSurface),
        secondaryLabelStyle: TextStyle(color: colors.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ── Tab Bar ──
      tabBarTheme: TabBarThemeData(
        labelColor: colors.onPrimary,
        unselectedLabelColor: colors.onPrimary.withValues(alpha: 0.7),
        indicatorColor: colors.onPrimary,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: colors.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ── Input Fields ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Dialogs ──
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Bottom Sheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.cardSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 0.5,
        space: 1,
      ),

      // ── Switch / Toggle ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.accent;
          return colors.subtleText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent.withValues(alpha: 0.3);
          }
          return colors.border;
        }),
      ),

      // ── Register AppColors extension ──
      extensions: const <ThemeExtension>[
        AppColors.light,
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🌙 DARK THEME — Deep Midnight Navy & Teal
  // ═══════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    const colors = AppColors.dark;

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,

      // ── Color Scheme ──
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF0E9F90),
        secondary: Color(0xFF1E293B),
        tertiary: Color(0xFF00A896),
        surface: Color(0xFF111C30),
        onSurface: Color(0xFFF8FAFC),
        error: Color(0xFFF87171),
      ),

      scaffoldBackgroundColor: colors.background,

      // ── App Bar ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colors.primaryDark,
        foregroundColor: colors.onSurface,
        titleTextStyle: TextStyle(
          color: colors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.cardSurface,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border, width: 0.5),
        ),
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.primary,
        labelStyle: TextStyle(color: colors.onSurface),
        secondaryLabelStyle: TextStyle(color: colors.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ── Tab Bar ──
      tabBarTheme: TabBarThemeData(
        labelColor: colors.onSurface,
        unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
        indicatorColor: colors.primary,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: colors.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ── Input Fields ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Dialogs ──
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Bottom Sheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.cardSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 0.5,
        space: 1,
      ),

      // ── Switch / Toggle ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.accent;
          return colors.subtleText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.accent.withValues(alpha: 0.3);
          }
          return colors.border;
        }),
      ),

      // ── Register AppColors extension ──
      extensions: const <ThemeExtension>[
        AppColors.dark,
      ],
    );
  }
}
