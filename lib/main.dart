import 'package:flutter/material.dart';

import 'app_state.dart';
import 'config/app_config.dart';

import 'config/app_theme.dart';

import 'presentation/app_shell.dart';

void main() => runApp(const HideAndSeekApp());

class HideAndSeekApp extends StatefulWidget {
  const HideAndSeekApp({super.key});

  @override
  State<HideAndSeekApp> createState() => _HideAndSeekAppState();
}

class _HideAndSeekAppState extends State<HideAndSeekApp> {
  final state = AppState();

  @override

  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(state.themePreference),
          home: AppShell(state: state),
        ),

  Widget build(BuildContext context) => MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff315c46),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xfff5f6f1),
          cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 52),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        home: AppShell(state: state),

      );
}
