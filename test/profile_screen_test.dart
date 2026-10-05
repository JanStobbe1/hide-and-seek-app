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
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('Spelvaluta'), findsNothing);
      expect(find.text('Ranking bij vrienden'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Punten & ranking'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('Ik begin je teller op 1.000 punten.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'player markers keep a clear two-tone accent after selection',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerMarkerBadge(marker: PlayerMarker.wolf),
          ),
        ),
      );

      final badge = tester.widget<Container>(
        find.byKey(const ValueKey('player-marker-badge-wolf')),
      );
      final decoration = badge.decoration! as BoxDecoration;
      expect(decoration.color, markerAccentColor(PlayerMarker.wolf));
      expect(decoration.border, isNull);
      expect(
        tester.widget<Icon>(find.byIcon(markerIcon(PlayerMarker.wolf))).color,
        Colors.white,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerMarkerBadge(marker: PlayerMarker.ghost),
          ),
        ),
      );
      final ghostBadge = find.byKey(
        const ValueKey('player-marker-badge-ghost'),
      );
      final ghostPainter = find.descendant(
        of: ghostBadge,
        matching: find.byType(CustomPaint),
      );
      expect(ghostPainter, findsOneWidget);
      expect(tester.getSize(ghostPainter), const Size.square(28));
      final badgeCenter = tester.getCenter(ghostBadge);
      final ghostCenter = tester.getCenter(ghostPainter);
      expect((badgeCenter.dx - ghostCenter.dx).abs(), lessThan(1));
      expect((badgeCenter.dy - ghostCenter.dy).abs(), lessThan(1));
      expect(find.byIcon(Icons.cruelty_free), findsNothing);
    },
  );
}
