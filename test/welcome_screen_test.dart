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
          onContinue: () {},
        ),
      ),
    );

    expect(find.byType(StobbeGuide), findsOneWidget);
    expect(find.byKey(const Key('welcome-greeting')), findsOneWidget);
    expect(find.textContaining('Noor'), findsOneWidget);
    expect(find.text('Naar mijn spellen'), findsOneWidget);
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
