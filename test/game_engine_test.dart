import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/domain/game_engine.dart';
import 'package:verstobbertje/domain/models.dart';

void main() {
  group('ActiveGameState', () {
    test('simulated found-player event increments progress', () {
      const state = ActiveGameState(playersFound: 5, totalPlayers: 20);
      expect(state.playerFound().playersFound, 6);
    });
    test('cannot find a player after completion', () {
      const state = ActiveGameState(status: GameStatus.completed, playersFound: 5);
      expect(state.playerFound().playersFound, 5);
    });
    test('finish transitions an active game to completed', () {
      expect(const ActiveGameState().finish().status, GameStatus.completed);
    });
    test('invisibility is single use', () {
      expect(const ActiveGameState().useInvisibility().invisibilityAvailable, isFalse);
    });
  });
}
