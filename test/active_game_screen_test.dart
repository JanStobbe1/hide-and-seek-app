import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/presentation/active_game_screen.dart';
import 'package:verstobbertje/domain/stobbe_powers.dart';

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

  testWidgets('overview stays focused on status, score and ranking', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(
      MaterialApp(home: ActiveGameScreen(state: state)),
    );
    await tester.tap(find.byIcon(Icons.dashboard_outlined));
    await tester.pump();

    expect(find.textContaining('spelpunten verzameld'), findsOneWidget);
    expect(find.text('3e'), findsOneWidget);
    expect(find.text('van 20 spelers'), findsOneWidget);
    expect(find.text('Zoekgebied'), findsNothing);
    expect(find.textContaining('Simuleer'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('map uses buttons and supports zoom, catch and detective help', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(
      MaterialApp(home: ActiveGameScreen(state: state)),
    );
    await tester.pump();

    expect(find.byType(PageView), findsNothing);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('PAK SPELER'), findsOneWidget);
    expect(find.byTooltip('Inzoomen'), findsOneWidget);
    expect(find.byTooltip('Uitzoomen'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.byIcon(Icons.cruelty_free), findsOneWidget);
    expect(find.byIcon(Icons.navigation), findsNothing);
    expect(find.text('Mila'), findsNothing);

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final controller = viewer.transformationController!;
    final viewerSize = tester.getSize(find.byType(InteractiveViewer));
    final center = viewerSize.center(Offset.zero);
    final sceneCenterBefore = controller.toScene(center);

    await tester.tap(find.byTooltip('Inzoomen'));
    await tester.pump();

    final sceneCenterAfter = controller.toScene(center);
    expect((sceneCenterAfter - sceneCenterBefore).distance, lessThan(0.01));

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

    await tester.tap(find.text('Digitale drone'));
    await tester.pump();
    expect(find.textContaining('ruimer zicht'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('using a power consumes it and returns to the animated map', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(
      MaterialApp(home: ActiveGameScreen(state: state)),
    );
    await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
    await tester.pump();

    expect(find.text('×1'), findsNWidgets(2));
    await tester.tap(
      find.widgetWithText(FilledButton, 'INZETTEN').first,
    );
    await tester.pump();

    expect(find.text('PAK SPELER'), findsOneWidget);
    expect(find.text('Drone verkent het speelveld'), findsOneWidget);
    expect(
      state.powerInventory.slotFor(StobbePowerKind.digitalDrone)!.quantity,
      0,
    );
    await tester.pumpWidget(const SizedBox());
  });

;
}
