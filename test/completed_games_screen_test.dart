import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/presentation/games_screens.dart';

void main() {
  testWidgets('completed game opens result and fellow players', (tester) async {
    final state = AppState();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: CompletedGamesScreen(state: state))),
    );

    await tester.tap(find.text('Verstopper'));
    await tester.pumpAndSettle();

    expect(find.text('Jouw resultaat'), findsOneWidget);
    expect(find.text('Nummer 7'), findsOneWidget);
    expect(find.byTooltip('Vraag het de Stobbedetective'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Houda'), 300);
    expect(find.text('Medespelers'), findsOneWidget);
    expect(find.text('Houda'), findsOneWidget);

    await tester.tap(find.byTooltip('Vraag het de Stobbedetective'));
    await tester.pump();
    expect(find.text('Spelresultaat'), findsOneWidget);
    expect(find.textContaining('eindpositie'), findsOneWidget);
  });
}
