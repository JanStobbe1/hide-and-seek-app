import 'package:flutter/material.dart';

import '../domain/profile_models.dart';

abstract final class AppTheme {
  static const defaultPreference = ThemePreference.forest;

  static Color seedFor(ThemePreference preference) => switch (preference) {
        ThemePreference.forest => const Color(0xff315c46),
        ThemePreference.ocean => const Color(0xff176b87),
        ThemePreference.sunset => const Color(0xffa34d32),
        ThemePreference.violet => const Color(0xff6650a4),
      };

  static String labelFor(ThemePreference preference) => switch (preference) {
        ThemePreference.forest => 'Bosgroen',
        ThemePreference.ocean => 'Oceaanblauw',
        ThemePreference.sunset => 'Zonsondergang',
        ThemePreference.violet => 'Avontuurspaars',
      };

  static ThemeData build(ThemePreference preference) {
    final colors = ColorScheme.fromSeed(
      seedColor: seedFor(preference),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surfaceContainerLowest,
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
