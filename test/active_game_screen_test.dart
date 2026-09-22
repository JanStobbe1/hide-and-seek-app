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
    await tester.pump();
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
    await tester.pump();
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
  testWidgets('map uses buttons and supports zoom, catch and detective help', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(
      MaterialApp(home: ActiveGameScreen(state: state)),
    );

    expect(find.byType(PageView), findsNothing);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('PAK SPELER'), findsOneWidget);
    expect(find.byTooltip('Inzoomen'), findsOneWidget);
    expect(find.byTooltip('Uitzoomen'), findsOneWidget);

    await tester.tap(find.byTooltip('Vraag het de Stobbedetective'));
    await tester.pump();
    expect(find.text('Het speelveld'), findsOneWidget);
    expect(find.textContaining('knijp met twee vingers'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Stobbetas shows collected power tokens', (tester) async {
    final state = AppState();
    await tester.pumpWidget(
      MaterialApp(home: ActiveGameScreen(state: state)),
    );

    await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
    await tester.pump();

    expect(find.text('Jouw Stobbetas'), findsOneWidget);
    expect(find.text('Digitale drone'), findsOneWidget);
    expect(find.text('Arm van de Stobbe'), findsOneWidget);
    expect(find.text('Onzichtbaar'), findsOneWidget);
    expect(find.text('Puntenkisten'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
