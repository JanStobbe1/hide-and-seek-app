import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/domain/models.dart';
import 'package:verstobbertje/presentation/games_screens.dart';

void main() {
  testWidgets('invitation details include the start year', (tester) async {
    final game = Game(
      id: 'year-test',
      name: 'Winterjacht',
      organizer: 'Noor',
      description: 'Een uitnodiging voor een nieuw spel.',
      area: const SearchArea(
        country: 'Nederland',
        province: 'Noord-Holland',
        city: 'Amsterdam',
        neighbourhood: 'Centrum',
        specificArea: 'Niet van toepassing',
      ),
      status: GameStatus.available,
      duration: const Duration(minutes: 90),
      participants: 4,
      maxParticipants: 20,
      distanceKm: 2,
      startCondition: StartCondition.scheduled,
      scheduledStart: DateTime(2027, 1, 10, 13),
      isPublic: true,
    );

    await tester.pumpWidget(
      MaterialApp(home: GameDetailScreen(state: AppState(), game: game)),
    );

    expect(find.textContaining('10 januari 2027'), findsOneWidget);
  });
}
