import 'package:flutter/material.dart';

import 'app_state.dart';
import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'presentation/app_shell.dart';
import 'presentation/cover_screen.dart';

void main() => runApp(const HideAndSeekApp());

class HideAndSeekApp extends StatefulWidget {
  const HideAndSeekApp({super.key});

  @override
  State<HideAndSeekApp> createState() => _HideAndSeekAppState();
}

class _HideAndSeekAppState extends State<HideAndSeekApp> {
  final state = AppState();
  bool showCover = true;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(state.themePreference),
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: showCover
                ? CoverScreen(
                    key: const ValueKey('cover'),
                    onEnter: () => setState(() => showCover = false),
                  )
                : AppShell(
                    key: const ValueKey('app'),
                    state: state,
                  ),
          ),
        ),
      );
}
