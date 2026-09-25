import 'package:flutter/material.dart';

import 'stobbe_guide.dart';

String greetingForHour(int hour) {
  if (hour >= 5 && hour < 12) return 'Goedemorgen';
  if (hour >= 12 && hour < 18) return 'Goedemiddag';
  if (hour >= 18) return 'Goedenavond';
  return 'Goedenacht';
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    required this.playerName,
    required this.backendConnected,
    required this.backendError,
    required this.onContinue,
    super.key,
  });

  final String playerName;
  final bool backendConnected;
  final String? backendError;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final greeting = greetingForHour(DateTime.now().hour);

    return Scaffold(
      appBar: AppBar(title: const Text('Welkom bij Verstobbertje')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const StobbeGuide(
                    explanation:
                        'Ik leg je stap voor stap uit hoe Verstobbertje werkt.',
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '$greeting, $playerName!',
                    key: const Key('welcome-greeting'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Je profiel is klaar. Bekijk nu de spellen en kies je volgende avontuur.',
                    textAlign: TextAlign.center,
                  ),
                  if (backendConnected) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Je profiel is opgeslagen.',
                      key: Key('backend-success'),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (backendError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Je profiel kon nog niet worden opgeslagen. '
                      'Je kunt wel verdergaan; we proberen het later opnieuw.',
                      key: const Key('backend-error'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('Naar mijn spellen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
