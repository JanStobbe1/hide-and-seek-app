import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/presentation/home_screen.dart';

void main() {
  testWidgets('discover count excludes games already joined', (tester) async {
    final state = AppState();
    expect(state.join('wats'), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            state: state,
            onNavigate: (_) {},
            onCreate: () {},
          ),
        ),
      ),
    );

    final discoveryCard = find
        .ancestor(
          of: find.text('Spellen ontdekken'),
          matching: find.byType(Card),
        )
        .first;
    expect(
      find.descendant(of: discoveryCard, matching: find.text('4')),
      findsOneWidget,
    );
  });

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
