import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/presentation/active_game_screen.dart';

void main() {
  testWidgets('active game shows personal/global counters and zone status', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(
      MaterialApp(home: ActiveGameScreen(state: state)),
    );

    expect(find.textContaining('5 van de 20 gevonden'), findsOneWidget);
    expect(find.textContaining('2 van 5 door mij gevonden'), findsOneWidget);
    expect(find.text('Binnen speelgebied'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('confirmed outside state shows alarm and return clears it', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(
      MaterialApp(home: ActiveGameScreen(state: state)),
    );

    await tester.ensureVisible(find.text('Bevestig buiten zone'));
    await tester.tap(find.text('Bevestig buiten zone'));
    await tester.pump();
    expect(find.text('Je staat buiten het actieve speelveld'), findsOneWidget);

    await tester.tap(find.text('Keer terug in zone'));
    await tester.pump();
    expect(find.text('Je staat buiten het actieve speelveld'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
