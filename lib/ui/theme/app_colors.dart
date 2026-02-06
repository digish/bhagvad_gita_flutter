import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  // Brand Colors
  final Color gitaBlue; // The custom "bluish" brand color (0xFF047BC0)

  // Semantic Colors - can map to other colors
  final Color simpleThemeToggle;
  final Color speedDialBg;
  final Color speedDialFg;
  final Color parayanGradientStart;
  final Color defaultGradientEnd;
  final Color searchResultGradientStart;
  final Color chapterGradientStart;
  final Color lotusGlow;
  final Color lotusLines;
  final Color cardBorder;
  final Color cardTitle;
  final Color cardText;
  final Color highlightColor;

  const AppColors({
    required this.gitaBlue,
    required this.simpleThemeToggle,
    required this.speedDialBg,
    required this.speedDialFg,
    required this.parayanGradientStart,
    required this.defaultGradientEnd,
    required this.searchResultGradientStart,
    required this.chapterGradientStart,
    required this.lotusGlow,
    required this.lotusLines,
    required this.cardBorder,
    required this.cardTitle,
    required this.cardText,
    required this.highlightColor,
  });

  @override
  AppColors copyWith({
    Color? gitaBlue,
    Color? simpleThemeToggle,
    Color? speedDialBg,
    Color? speedDialFg,
    Color? parayanGradientStart,
    Color? defaultGradientEnd,
    Color? searchResultGradientStart,
    Color? chapterGradientStart,
    Color? lotusGlow,
    Color? lotusLines,
    Color? cardBorder,
    Color? cardTitle,
    Color? cardText,
    Color? highlightColor,
  }) {
    return AppColors(
      gitaBlue: gitaBlue ?? this.gitaBlue,
      simpleThemeToggle: simpleThemeToggle ?? this.simpleThemeToggle,
      speedDialBg: speedDialBg ?? this.speedDialBg,
      speedDialFg: speedDialFg ?? this.speedDialFg,
      parayanGradientStart: parayanGradientStart ?? this.parayanGradientStart,
      defaultGradientEnd: defaultGradientEnd ?? this.defaultGradientEnd,
      searchResultGradientStart:
          searchResultGradientStart ?? this.searchResultGradientStart,
      chapterGradientStart: chapterGradientStart ?? this.chapterGradientStart,
      lotusGlow: lotusGlow ?? this.lotusGlow,
      lotusLines: lotusLines ?? this.lotusLines,
      cardBorder: cardBorder ?? this.cardBorder,
      cardTitle: cardTitle ?? this.cardTitle,
      cardText: cardText ?? this.cardText,
      highlightColor: highlightColor ?? this.highlightColor,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      gitaBlue: Color.lerp(gitaBlue, other.gitaBlue, t)!,
      simpleThemeToggle: Color.lerp(
        simpleThemeToggle,
        other.simpleThemeToggle,
        t,
      )!,
      speedDialBg: Color.lerp(speedDialBg, other.speedDialBg, t)!,
      speedDialFg: Color.lerp(speedDialFg, other.speedDialFg, t)!,
      parayanGradientStart: Color.lerp(
        parayanGradientStart,
        other.parayanGradientStart,
        t,
      )!,
      defaultGradientEnd: Color.lerp(
        defaultGradientEnd,
        other.defaultGradientEnd,
        t,
      )!,
      searchResultGradientStart: Color.lerp(
        searchResultGradientStart,
        other.searchResultGradientStart,
        t,
      )!,
      chapterGradientStart: Color.lerp(
        chapterGradientStart,
        other.chapterGradientStart,
        t,
      )!,
      lotusGlow: Color.lerp(lotusGlow, other.lotusGlow, t)!,
      lotusLines: Color.lerp(lotusLines, other.lotusLines, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardTitle: Color.lerp(cardTitle, other.cardTitle, t)!,
      cardText: Color.lerp(cardText, other.cardText, t)!,
      highlightColor: Color.lerp(highlightColor, other.highlightColor, t)!,
    );
  }

  // Pre-defined palettes
  static const light = AppColors(
    gitaBlue: Color(0xFF047BC0),
    simpleThemeToggle: Color(0xFF047BC0), // Uses Gita Blue in Light
    speedDialBg: Color(0xFF047BC0), // Uses Gita Blue in Light
    speedDialFg: Colors.white,
    parayanGradientStart: Color.fromARGB(255, 103, 108, 255),
    defaultGradientEnd: Color(0xFFFCE4EC), // Pink-50
    searchResultGradientStart: Color(0xFFF8BBD0), // Pink-100
    chapterGradientStart: Color(0xFFFFECB3), // Amber-100
    lotusGlow: Color.fromARGB(255, 255, 64, 210), // Pink glow
    lotusLines: Color.fromARGB(
      50,
      164,
      6,
      138,
    ), // Pink lines (approx 0.2 opacity)
    cardBorder: Color.fromARGB(50, 233, 30, 99), // Pink opacity 0.2
    cardTitle: Color.fromARGB(204, 136, 14, 79), // Pink 900 opacity 0.8
    cardText: Color(0xFF3E2723), // Brown 900
    highlightColor: Color(0xFFD81B60), // Deep Pink
  );

  static const dark = AppColors(
    gitaBlue: Color(0xFF047BC0), // Still available if needed
    simpleThemeToggle: Colors.orange, // Primary color (mapped in AppTheme)
    speedDialBg: Colors.orange, // Primary color (mapped in AppTheme)
    speedDialFg: Color(0xFFE0E0E0), // OnPrimary/OnSurface
    parayanGradientStart: Color.fromARGB(255, 60, 60, 100), // Darker version?
    defaultGradientEnd: Color(0xFF1E1E1E),
    searchResultGradientStart: Color(0xFF4A1425), // Dark Pinkish
    chapterGradientStart: Color(0xFF4A340F), // Dark Amberish
    lotusGlow: Color(0xFFFFD54F), // Amber-300
    lotusLines: Color.fromARGB(77, 255, 193, 7), // Amber 0.3 opacity
    cardBorder: Color.fromARGB(128, 255, 215, 0), // Gold 0.5 opacity
    cardTitle: Color(0xFFFFD700), // Gold
    cardText: Color.fromARGB(217, 255, 255, 255), // White 0.85
    highlightColor: Color(0xFFFFD700), // Gold
  );
}
