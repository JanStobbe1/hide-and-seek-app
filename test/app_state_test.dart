import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/domain/models.dart';
import 'package:verstobbertje/domain/profile_models.dart';

void main() {
  test('finishGame is idempotent and reset restores the initial state', () {
    final state = AppState();

    state.finishGame();
    state.finishGame();

    expect(state.gamesPlayed, 6);
    expect(state.activeGame.status, GameStatus.completed);
    expect(state.gameFinished, isTrue);

    state.setPrivacy('Deel mijn naam', false);
    state.setDisplayName('A. Speler');
    state.setThemePreference(ThemePreference.ocean);
    state.setPlayerMarker(PlayerMarker.wolf);
    state.reset();

    expect(state.gamesPlayed, 5);
    expect(state.activeGame.status, GameStatus.active);
    expect(state.activeGame.playersFound, 0);
    expect(state.totalHiders, 15);
    expect(state.activeHiders, 15);
    expect(state.gameFinished, isFalse);
    expect(state.privacy['Deel mijn naam'], isTrue);
    expect(state.displayName, 'Arie');
    expect(state.themePreference, ThemePreference.forest);
    expect(state.playerMarker, PlayerMarker.ghost);
  });

  test('finding a player keeps roster progress consistent', () {
    final state = AppState();

    state.foundPlayer();

    expect(state.activeGame.playersFound, 1);
    expect(state.foundHiders, 1);
    expect(state.activeHiders, 14);
    expect(state.totalHiders, 15);
  });

  test('active game ticks down and completion is counted once', () {
    final state = AppState(activeGameDuration: const Duration(seconds: 3));
    final initial = state.activeGame.countdown.remaining;

    state.tickActiveGame();
    state.tickActiveGame(initial);
    state.tickActiveGame();

    expect(state.activeGame.countdown.remaining, Duration.zero);
    expect(state.gamesPlayed, 6);
    expect(initial, const Duration(seconds: 3));
  });
}
