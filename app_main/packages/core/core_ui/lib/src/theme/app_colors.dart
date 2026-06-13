import 'package:flutter/material.dart';

/// Mizan's semantic color system — "Emerald Whisper" palette.
///
/// Usage: `Theme.of(context).extension<AppColors>()!` or the
/// shorthand `context.appColors`.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    // ── Core Palette ──
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.cardSurface,
    required this.accent,

    // ── Text ──
    required this.onPrimary,
    required this.onSurface,
    required this.subtleText,

    // ── Semantic Status ──
    required this.success,
    required this.successBackground,
    required this.error,
    required this.errorBackground,
    required this.warning,
    required this.warningBackground,
    required this.info,
    required this.infoBackground,

    // ── Accounting-Specific ──
    required this.favorable,
    required this.unfavorable,
    required this.debit,
    required this.credit,
    required this.sectionHeader,

    // ── Borders & Dividers ──
    required this.border,
    required this.divider,
  });

  // ── Core Palette ──
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color surface;
  final Color background;
  final Color cardSurface;
  final Color accent;

  // ── Text ──
  final Color onPrimary;
  final Color onSurface;
  final Color subtleText;

  // ── Semantic Status ──
  final Color success;
  final Color successBackground;
  final Color error;
  final Color errorBackground;
  final Color warning;
  final Color warningBackground;
  final Color info;
  final Color infoBackground;

  // ── Accounting-Specific ──
  final Color favorable;
  final Color unfavorable;
  final Color debit;
  final Color credit;
  final Color sectionHeader;

  // ── Borders & Dividers ──
  final Color border;
  final Color divider;

  // ═══════════════════════════════════════════════════════════
  // LIGHT MODE — Emerald Whisper
  // ═══════════════════════════════════════════════════════════
  static const light = AppColors(
    // Core
    primary:      Color(0xFF0F3D3E),
    primaryDark:  Color(0xFF0A2E2F),
    secondary:    Color(0xFF467373),
    surface:      Color(0xFFD2E8E3),
    background:   Color(0xFFF5FAF8),
    cardSurface:  Color(0xFFFFFFFF),
    accent:       Color(0xFF2D8F7B),

    // Text
    onPrimary:    Color(0xFFFFFFFF),
    onSurface:    Color(0xFF1A1A1A),
    subtleText:   Color(0xFF6B7280),

    // Semantic
    success:           Color(0xFF22C55E),
    successBackground: Color(0xFFDCFCE7),
    error:             Color(0xFFEF4444),
    errorBackground:   Color(0xFFFEE2E2),
    warning:           Color(0xFFF59E0B),
    warningBackground: Color(0xFFFEF3C7),
    info:              Color(0xFF3B82F6),
    infoBackground:    Color(0xFFDBEAFE),

    // Accounting
    favorable:     Color(0xFF16A34A),
    unfavorable:   Color(0xFFDC2626),
    debit:         Color(0xFF2563EB),
    credit:        Color(0xFF16A34A),
    sectionHeader: Color(0xFF0F3D3E),

    // Borders
    border:  Color(0xFFE5E7EB),
    divider: Color(0xFFD1D5DB),
  );

  // ═══════════════════════════════════════════════════════════
  // DARK MODE — Deep Midnight Navy & Teal
  // ═══════════════════════════════════════════════════════════
  static const dark = AppColors(
    // Core
    primary:      Color(0xFF0E9F90),
    primaryDark:  Color(0xFF08101E),
    secondary:    Color(0xFF1E293B),
    surface:      Color(0xFF111C30),
    background:   Color(0xFF0B1527),
    cardSurface:  Color(0xFF162238),
    accent:       Color(0xFF00A896),

    // Text
    onPrimary:    Color(0xFFFFFFFF),
    onSurface:    Color(0xFFF8FAFC),
    subtleText:   Color(0xFF94A3B8),

    // Semantic
    success:           Color(0xFF4ADE80),
    successBackground: Color(0xFF052E16),
    error:             Color(0xFFF87171),
    errorBackground:   Color(0xFF450A0A),
    warning:           Color(0xFFFBBF24),
    warningBackground: Color(0xFF451A03),
    info:              Color(0xFF38BDF8),
    infoBackground:    Color(0xFF0C4A6E),

    // Accounting
    favorable:     Color(0xFF4ADE80),
    unfavorable:   Color(0xFFF87171),
    debit:         Color(0xFF38BDF8),
    credit:        Color(0xFF4ADE80),
    sectionHeader: Color(0xFF0E9F90),

    // Borders
    border:  Color(0xFF233554),
    divider: Color(0xFF1E2D4A),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryDark,
    Color? secondary,
    Color? surface,
    Color? background,
    Color? cardSurface,
    Color? accent,
    Color? onPrimary,
    Color? onSurface,
    Color? subtleText,
    Color? success,
    Color? successBackground,
    Color? error,
    Color? errorBackground,
    Color? warning,
    Color? warningBackground,
    Color? info,
    Color? infoBackground,
    Color? favorable,
    Color? unfavorable,
    Color? debit,
    Color? credit,
    Color? sectionHeader,
    Color? border,
    Color? divider,
  }) {
    return AppColors(
      primary:            primary            ?? this.primary,
      primaryDark:        primaryDark        ?? this.primaryDark,
      secondary:          secondary          ?? this.secondary,
      surface:            surface            ?? this.surface,
      background:         background         ?? this.background,
      cardSurface:        cardSurface        ?? this.cardSurface,
      accent:             accent             ?? this.accent,
      onPrimary:          onPrimary          ?? this.onPrimary,
      onSurface:          onSurface          ?? this.onSurface,
      subtleText:         subtleText         ?? this.subtleText,
      success:            success            ?? this.success,
      successBackground:  successBackground  ?? this.successBackground,
      error:              error              ?? this.error,
      errorBackground:    errorBackground    ?? this.errorBackground,
      warning:            warning            ?? this.warning,
      warningBackground:  warningBackground  ?? this.warningBackground,
      info:               info               ?? this.info,
      infoBackground:     infoBackground     ?? this.infoBackground,
      favorable:          favorable          ?? this.favorable,
      unfavorable:        unfavorable        ?? this.unfavorable,
      debit:              debit              ?? this.debit,
      credit:             credit             ?? this.credit,
      sectionHeader:      sectionHeader      ?? this.sectionHeader,
      border:             border             ?? this.border,
      divider:            divider            ?? this.divider,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary:            Color.lerp(primary,            other.primary,            t)!,
      primaryDark:        Color.lerp(primaryDark,        other.primaryDark,        t)!,
      secondary:          Color.lerp(secondary,          other.secondary,          t)!,
      surface:            Color.lerp(surface,            other.surface,            t)!,
      background:         Color.lerp(background,         other.background,         t)!,
      cardSurface:        Color.lerp(cardSurface,        other.cardSurface,        t)!,
      accent:             Color.lerp(accent,             other.accent,             t)!,
      onPrimary:          Color.lerp(onPrimary,          other.onPrimary,          t)!,
      onSurface:          Color.lerp(onSurface,          other.onSurface,          t)!,
      subtleText:         Color.lerp(subtleText,         other.subtleText,         t)!,
      success:            Color.lerp(success,            other.success,            t)!,
      successBackground:  Color.lerp(successBackground,  other.successBackground,  t)!,
      error:              Color.lerp(error,              other.error,              t)!,
      errorBackground:    Color.lerp(errorBackground,    other.errorBackground,    t)!,
      warning:            Color.lerp(warning,            other.warning,            t)!,
      warningBackground:  Color.lerp(warningBackground,  other.warningBackground,  t)!,
      info:               Color.lerp(info,               other.info,              t)!,
      infoBackground:     Color.lerp(infoBackground,     other.infoBackground,     t)!,
      favorable:          Color.lerp(favorable,          other.favorable,          t)!,
      unfavorable:        Color.lerp(unfavorable,        other.unfavorable,        t)!,
      debit:              Color.lerp(debit,              other.debit,              t)!,
      credit:             Color.lerp(credit,             other.credit,             t)!,
      sectionHeader:      Color.lerp(sectionHeader,      other.sectionHeader,      t)!,
      border:             Color.lerp(border,             other.border,             t)!,
      divider:            Color.lerp(divider,            other.divider,            t)!,
    );
  }
}

/// Convenience extension so you can write `context.appColors` anywhere.
extension AppColorsExtension on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
