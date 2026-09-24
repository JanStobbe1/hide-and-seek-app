import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/presentation/onboarding_screen.dart';
import 'package:verstobbertje/presentation/stobbe_guide.dart';

void main() {
  testWidgets('new player completes profile and safety onboarding', (
    tester,
  ) async {
    final state = AppState();
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          state: state,
          onComplete: () => completed = true,
        ),
      ),
    );

    expect(find.text('Een avontuur in de buitenlucht'), findsOneWidget);
    expect(find.byType(StobbeGuide), findsOneWidget);
    await tester.tap(find.text('Volgende'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('onboarding-name')), 'Noor');
    await tester.tap(find.text('Volgende'));
    await tester.pumpAndSettle();
    expect(find.text('Zo werkt een spel'), findsOneWidget);
    expect(find.byType(StobbeGuide), findsOneWidget);
    await tester.tap(find.text('Volgende'));
    await tester.pumpAndSettle();
    expect(find.text('Speel slim en veilig'), findsOneWidget);
    expect(find.byType(StobbeGuide), findsOneWidget);
    await tester.tap(find.text('Naar de inhoudsopgave'));

    expect(completed, isTrue);
    expect(state.displayName, 'Noor');
  });
}
