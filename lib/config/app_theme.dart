import 'package:flutter/material.dart';

import '../domain/profile_models.dart';

abstract final class AppTheme {
  static const defaultPreference = ThemePreference.forest;

  static Color seedFor(ThemePreference preference) => switch (preference) {
        ThemePreference.forest => const Color(0xff657267),
        ThemePreference.ocean => const Color(0xff586a78),
        ThemePreference.sunset => const Color(0xff8a7468),
        ThemePreference.violet => const Color(0xff665a78),
        ThemePreference.graphite => const Color(0xff565b60),
        ThemePreference.rosewood => const Color(0xff795f63),
      };

  static String labelFor(ThemePreference preference) => switch (preference) {
        ThemePreference.forest => 'Mat saliegroen',
        ThemePreference.ocean => 'Leisteenblauw',
        ThemePreference.sunset => 'Warm taupe',
        ThemePreference.violet => 'Fluweelpaars',
        ThemePreference.graphite => 'Zacht grafiet',
        ThemePreference.rosewood => 'Mat rozenhout',
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
