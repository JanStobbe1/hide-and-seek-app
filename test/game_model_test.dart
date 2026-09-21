import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/data/mock_game_repository.dart';
import 'package:verstobbertje/domain/models.dart';

void main() {
  test('scheduled games retain their editable date and derive an end time', () {
    final start = DateTime(2027, 8, 25, 16, 30);
    final game = Game(
      id: 'scheduled',
      name: 'Avondspel',
      organizer: 'Arie',
      description: 'Test',
      area: demoArea,
      status: GameStatus.available,
      duration: const Duration(hours: 2),
      participants: 1,
      maxParticipants: 12,
      distanceKm: 0,
      startCondition: StartCondition.scheduled,
      scheduledStart: start,
    );

    expect(game.scheduledStart, start);
    expect(game.scheduledEnd, DateTime(2027, 8, 25, 18, 30));
    expect(game.participantThreshold, isNull);
  });

  test('participant-start games retain a threshold without a date', () {
    const game = Game(
      id: 'threshold',
      name: 'Groepsspel',
      organizer: 'Arie',
      description: 'Test',
      area: demoArea,
      status: GameStatus.available,
      duration: Duration(hours: 2),
      participants: 1,
      maxParticipants: 12,
      distanceKm: 0,
      startCondition: StartCondition.participantCount,
      participantThreshold: 8,
    );

    expect(game.participantThreshold, 8);
    expect(game.scheduledStart, isNull);
    expect(game.scheduledEnd, isNull);
  });
}
