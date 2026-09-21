import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/data/mock_game_repository.dart';
import 'package:verstobbertje/domain/models.dart';

void main() {
  test('joining locally adds a game once and reset restores demo state', () {
    final repository = MockGameRepository();
    repository.join('epic');
    repository.join('epic');
    expect(repository.joinedGames, hasLength(1));
    expect(repository.joinedGames.single.participants, 21);
    repository.reset();
    expect(repository.joinedGames, isEmpty);
    expect(repository.availableGames.first.participants, 20);
  });

  test('publishing adds the configured game and reset removes it', () {
    final repository = MockGameRepository();
    const area = SearchArea(
      country: 'België',
      province: 'Antwerpen',
      city: 'Mechelen',
      neighbourhood: 'Centrum',
      specificArea: 'Grote Markt',
    );
    const game = Game(
      id: 'created',
      name: 'Nieuw spel',
      organizer: 'Arie',
      description: 'Test',
      area: area,
      status: GameStatus.available,
      duration: Duration(hours: 1),
      participants: 1,
      maxParticipants: 12,
      distanceKm: 1,
      startCondition: StartCondition.participantCount,
      participantThreshold: 6,
    );

    repository.publish(game);

    expect(repository.availableGames.last.area.city, 'Mechelen');
    expect(repository.availableGames.last.participantThreshold, 6);
    repository.reset();
    expect(
      repository.availableGames.any((item) => item.id == 'created'),
      isFalse,
    );
  });
}
