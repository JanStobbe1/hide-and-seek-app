import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/presentation/home_screen.dart';

void main() {
  testWidgets('contents page opens its chapters', (tester) async {
    final state = AppState();
    var destination = -1;
    var createTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            state: state,
            onNavigate: (value) => destination = value,
            onCreate: () => createTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('INHOUDSOPGAVE'), findsOneWidget);
    expect(find.text('Waar begint jouw\nvolgende avontuur?'), findsOneWidget);
    expect(find.text('VERDER SPELEN'), findsNothing);

    await tester.tap(find.text('Nieuw spel'));
    expect(createTapped, isTrue);

    await tester.tap(find.text('Spellen ontdekken'));
    expect(destination, 2);
  });
}
