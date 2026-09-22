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
    await tester.tap(find.byIcon(Icons.dashboard_outlined));
    await tester.pump(const Duration(milliseconds: 300));

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
    await tester.tap(find.byIcon(Icons.dashboard_outlined));
    await tester.pump(const Duration(milliseconds: 300));

    state.registerZoneMeasurement(inside: false);
    state.registerZoneMeasurement(inside: false);
    await tester.pump();
    expect(state.inActiveZone, isFalse);

    final zoneAlarm = find.text('Je staat buiten het actieve speelveld');
    expect(zoneAlarm, findsOneWidget);

    state.registerZoneMeasurement(inside: true);
    await tester.pump();
    expect(state.inActiveZone, isTrue);
    expect(zoneAlarm, findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
