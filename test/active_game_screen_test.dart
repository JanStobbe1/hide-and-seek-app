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

    final confirmOutside = find.text('Bevestig buiten zone');
    await tester.scrollUntilVisible(
      confirmOutside,
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(confirmOutside);
    await tester.pump();
    expect(state.inActiveZone, isFalse);

    final zoneAlarm = find.text('Je staat buiten het actieve speelveld');
    await tester.scrollUntilVisible(
      zoneAlarm,
      -200,
      scrollable: find.byType(Scrollable),
    );
    expect(zoneAlarm, findsOneWidget);

    final returnToZone = find.text('Keer terug in zone');
    await tester.scrollUntilVisible(
      returnToZone,
      -100,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(returnToZone);
    await tester.pump();
    expect(state.inActiveZone, isTrue);
    expect(zoneAlarm, findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
