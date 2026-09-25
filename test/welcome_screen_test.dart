import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/presentation/stobbe_guide.dart';
import 'package:verstobbertje/presentation/welcome_screen.dart';

void main() {
  testWidgets('welcome screen greets the player before the app shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeScreen(
          playerName: 'Noor',
          backendConnected: false,
          backendError: null,
          onRetry: () async {},
          onContinue: () {},
        ),
      ),
    );

    expect(find.byType(StobbeGuide), findsOneWidget);
    expect(find.byKey(const Key('welcome-greeting')), findsOneWidget);
    expect(find.textContaining('Noor'), findsOneWidget);
    expect(find.text('Naar mijn spellen'), findsOneWidget);
  });

  testWidgets('welcome screen confirms successful backend registration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeScreen(
          playerName: 'Noor',
          backendConnected: true,
          backendError: null,
          onRetry: () async {},
          onContinue: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('backend-success')), findsOneWidget);
    expect(find.text('Je profiel is opgeslagen.'), findsOneWidget);
    expect(find.byKey(const Key('backend-retry')), findsNothing);
  });

  testWidgets('welcome screen offers retry when backend registration fails', (
    tester,
  ) async {
    var retryCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeScreen(
          playerName: 'Noor',
          backendConnected: false,
          backendError: 'connection_failed',
          onRetry: () async {
            retryCalled = true;
          },
          onContinue: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('backend-error')), findsOneWidget);
    expect(
      find.text('Je profiel kon nog niet worden opgeslagen.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('backend-retry')));
    expect(retryCalled, isTrue);
  });

  test('greeting periods use the requested time ranges', () {
    expect(greetingForHour(4), 'Goedenacht');
    expect(greetingForHour(5), 'Goedemorgen');
    expect(greetingForHour(11), 'Goedemorgen');
    expect(greetingForHour(12), 'Goedemiddag');
    expect(greetingForHour(17), 'Goedemiddag');
    expect(greetingForHour(18), 'Goedenavond');
    expect(greetingForHour(23), 'Goedenavond');
    expect(greetingForHour(0), 'Goedenacht');
  });
}
