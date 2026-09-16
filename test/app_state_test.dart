import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/domain/models.dart';

void main() {
  test('finishGame is idempotent and reset restores the initial state', () {
    final state = AppState();

    state.finishGame();
    state.finishGame();

    expect(state.gamesPlayed, 6);
    expect(state.activeGame.status, GameStatus.completed);
    expect(state.gameFinished, isTrue);

    state.setPrivacy('Deel mijn naam', false);
    state.reset();

    expect(state.gamesPlayed, 5);
    expect(state.activeGame.status, GameStatus.active);
    expect(state.activeGame.playersFound, 5);
    expect(state.gameFinished, isFalse);
    expect(state.privacy['Deel mijn naam'], isTrue);
  });

  test('finding a player moves deterministic progress from five to six', () {
    final state = AppState();

    state.foundPlayer();

    expect(state.activeGame.playersFound, 6);
  });
}
