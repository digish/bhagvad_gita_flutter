import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Shared seed color
  static const _seedColor = Colors.orange;

  // LIGHT THEME
  static ThemeData get light {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
        surface: Colors.white,
        onSurface: Colors.black87,
        surfaceContainerHighest: Colors.grey.shade100,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.grey.shade50,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.orange;
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.orange.withOpacity(0.5);
          }
          return null;
        }),
      ),
    );

    // Apply the light AppColors extension
    return base.copyWith(
      extensions: [
        AppColors.light.copyWith(
          // Ensure exact matches if needed, though defaults are set in AppColors.light
        ),
      ],
    );
  }

  // DARK THEME
  static ThemeData get dark {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E1E),
        onSurface: const Color(0xFFE0E0E0),
        surfaceContainerHighest: const Color(0xFF2C2C2C),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.orange;
          return Colors.white12;
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          return states.contains(MaterialState.selected)
              ? Colors.transparent
              : Colors.white24;
        }),
      ),
    );

    // Apply the dark AppColors extension
    // We update semantically linked colors to match the Theme's actual primary color
    // This allows us to change the seed above and have it cascade.
    final primary = base.colorScheme.primary;
    final onPrimary = base.colorScheme.onPrimary;

    return base.copyWith(
      extensions: [
        AppColors.dark.copyWith(
          simpleThemeToggle: primary,
          speedDialBg: primary,
          speedDialFg: onPrimary,
        ),
      ],
    );
  }
}
