import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/domain/models.dart';
import 'package:verstobbertje/presentation/games_screens.dart';

void main() {
  testWidgets('completed games are not shown under upcoming games',
      (tester) async {
    final state = AppState();
    final start = DateTime.now().add(const Duration(hours: 1));
    const area = SearchArea(
      country: 'Nederland',
      province: 'Flevoland',
      city: 'Dronten',
      neighbourhood: 'Alle',
      specificArea: 'Park',
    );

    Game makeGame(String id, String name, GameStatus status) => Game(
          id: id,
          name: name,
          organizer: 'Noor',
          description: '',
          area: area,
          status: status,
          duration: const Duration(hours: 1),
          participants: 2,
          maxParticipants: 10,
          distanceKm: 0,
          startCondition: StartCondition.scheduled,
          scheduledStart: start,
        );

    state.repository.replaceJoinedGames([
      makeGame('upcoming', 'Aankomend spel', GameStatus.waiting),
      makeGame('completed', 'Afgerond spel', GameStatus.completed),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MyGamesScreen(state: state)),
      ),
    );

    expect(find.text('Aankomend spel'), findsOneWidget);
    expect(find.text('Afgerond spel'), findsNothing);
  });
}
