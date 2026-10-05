import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/domain/profile_models.dart';
import 'package:verstobbertje/presentation/profile_screen.dart';
import 'package:verstobbertje/presentation/widgets.dart';

void main() {
  testWidgets(
    'profile shows inline name editing and explains points',
    (tester) async {
      final state = AppState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProfileScreen(state: state)),
        ),
      );

      expect(find.byKey(const Key('profile-display-name')), findsOneWidget);
      expect(find.byKey(const Key('profile-name-edit')), findsOneWidget);
      expect(find.text('1000'), findsNWidgets(2));
      expect(find.text('Spelvaluta'), findsNothing);
      expect(find.text('Ranking bij vrienden'), findsOneWidget);
      expect(
        find.textContaining('Ik begin je teller op 1.000 punten.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'player markers use a white outline and a color accent',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerMarkerBadge(marker: PlayerMarker.wolf),
          ),
        ),
      );

      final markerIcons = tester.widgetList<Icon>(
        find.byIcon(markerIcon(PlayerMarker.wolf)),
      );
      expect(markerIcons, hasLength(2));
      expect(
        markerIcons.map((icon) => icon.color),
        containsAll([Colors.white, markerAccentColor(PlayerMarker.wolf)]),
      );
    },
  );
}
