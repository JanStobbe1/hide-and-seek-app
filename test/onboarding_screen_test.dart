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

    expect(find.text('Aangenaam kennis te maken!'), findsOneWidget);
    expect(find.byType(StobbeGuide), findsOneWidget);
    await tester.enterText(find.byKey(const Key('onboarding-name')), 'Noor');
    await tester.tap(find.text('Volgende'));
    await tester.pumpAndSettle();
    expect(find.text('Hoeveel jaarringen heb jij?'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('onboarding-age')), '12');
    await tester.tap(find.text('Volgende'));
    await tester.pumpAndSettle();
    expect(find.text('Jouw pionnetje'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('onboarding-city')), 'Amsterdam');
    await tester.tap(find.text('Volgende'));
    await tester.pumpAndSettle();
    expect(find.text('Zo spelen we samen'), findsOneWidget);
    expect(find.byType(StobbeGuide), findsOneWidget);
    await tester.tap(find.text('Volgende'));
    await tester.pumpAndSettle();
    expect(find.text('Nog één belangrijke afspraak'), findsOneWidget);
    expect(find.byType(StobbeGuide), findsOneWidget);
    await tester.tap(find.text('Volgende'));
    await tester.pumpAndSettle();
    expect(find.text('Even controleren, detective'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-checklist')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-confirmation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding-signature')), findsOneWidget);
    await tester.tap(find.text('Akkoord en ondertekenen'));

    expect(completed, isTrue);
    expect(state.displayName, 'Noor');
    expect(state.profileAge, '12');
    expect(state.profileCity, 'Amsterdam');
  });
}
