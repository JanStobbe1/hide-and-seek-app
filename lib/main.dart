import 'package:flutter/material.dart';

import 'app_state.dart';
import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'presentation/app_shell.dart';
import 'presentation/cover_screen.dart';
import 'presentation/onboarding_screen.dart';
import 'presentation/welcome_screen.dart';

void main() => runApp(const HideAndSeekApp());

class HideAndSeekApp extends StatefulWidget {
  const HideAndSeekApp({super.key});

  @override
  State<HideAndSeekApp> createState() => _HideAndSeekAppState();
}

class _HideAndSeekAppState extends State<HideAndSeekApp> {
  final state = AppState();
  bool showCover = true;
  bool onboardingCompleted = false;
  bool welcomeCompleted = false;

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
                : onboardingCompleted
                    ? welcomeCompleted
                        ? AppShell(
                            key: const ValueKey('app'),
                            state: state,
                          )
                        : WelcomeScreen(
                            key: const ValueKey('welcome'),
                            playerName: state.displayName,
                            onContinue: () =>
                                setState(() => welcomeCompleted = true),
                          )
                    : OnboardingScreen(
                        key: const ValueKey('onboarding'),
                        state: state,
                        onComplete: () =>
                            setState(() => onboardingCompleted = true),
                      ),
          ),
        ),
      );
}
