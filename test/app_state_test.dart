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
    expect(state.activeGame.playersFound, 5);
    expect(state.gameFinished, isFalse);
    expect(state.privacy['Deel mijn naam'], isTrue);
    expect(state.displayName, 'Arie');
    expect(state.points, 1000);
    expect(state.themePreference, ThemePreference.forest);
    expect(state.playerMarker, PlayerMarker.ghost);
  });

  test('finding a player moves deterministic progress from five to six', () {
    final state = AppState();

    state.foundPlayer();

    expect(state.activeGame.playersFound, 6);
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

  test('found player can only rejoin when rule allows it', () {
    final state = AppState();
    state.questionPoints = 120;
    state.currentAttemptPoints = 120;

    state.playerWasFound();

    expect(state.playerActive, isFalse);
    expect(state.rejoinAfterFound(allowed: false), isFalse);
    expect(state.playerActive, isFalse);

    expect(state.rejoinAfterFound(allowed: true), isTrue);
    expect(state.playerActive, isTrue);
    expect(state.questionPoints, 0);
    expect(state.currentAttemptPoints, 0);
    expect(state.demoScores['me']!.value, 0);
  });

  test('game types expose distinct player-facing descriptions', () {
    expect(GameType.values, hasLength(2));
    expect(GameType.everyoneHunts.label, 'Iedereen jaagt');
    expect(GameType.classic.label, 'Klassiek');
    expect(
      GameType.classic.description,
      contains('Vaste zoekers'),
    );
  });
}
