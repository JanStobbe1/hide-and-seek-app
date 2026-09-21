import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/domain/friends.dart';
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

  test('accepted friend request is exposed as a friendship', () {
    final state = AppState();
    final now = DateTime(2026, 9, 21, 8);

    state.seedIncomingFriendRequest(
      playerId: 'player-mila',
      createdAt: now.subtract(const Duration(hours: 12)),
    );
    final request = state.incomingFriendRequestsAt(now).single;
    final decision = state.respondToFriendRequest(
      request,
      accept: true,
      now: now,
    );

    expect(decision, FriendDecision.friends);
    expect(state.incomingFriendRequestsAt(now), isEmpty);
    expect(state.friendshipPlayerIds, contains('player-mila'));
  });

  test('friend requests older than two days expire', () {
    final state = AppState();
    final now = DateTime(2026, 9, 21, 8);

    state.seedIncomingFriendRequest(
      playerId: 'player-old',
      createdAt: now.subtract(const Duration(days: 2, seconds: 1)),
    );

    expect(state.incomingFriendRequestsAt(now), isEmpty);
    expect(
      state.friendshipService.requests['player-old->me']?.decision,
      FriendDecision.expired,
    );
  });

  test('hider role cannot register finds and counts as hider', () {
    final state = AppState();
    state.setActiveRole(PlayerRole.hider);

    expect(state.findingState.players['me']?.role, PlayerRole.hider);
    expect(state.activeSeekers, 2);
    expect(state.totalHiders, 15);
    expect(state.foundPlayer(), isFalse);
    expect(state.personallyFoundHiders, 0);
  });

  test('hider found event updates hider state without seeker leakage', () {
    final state = AppState();
    state.setActiveRole(PlayerRole.hider);

    final registered = state.markCurrentHiderFound();

    expect(registered, isTrue);
    expect(state.currentHiderFound, isTrue);
    expect(state.currentHiderFoundAt, isNotNull);
    expect(state.foundHiders, 1);
    expect(state.activeHiders, 14);
    expect(state.activeGame.playersFound, 1);
    expect(state.personallyFoundHiders, 0);
  });

  test('switching back to seeker resets role-specific round state', () {
    final state = AppState();
    state.setActiveRole(PlayerRole.hider);
    state.markCurrentHiderFound();

    state.setActiveRole(PlayerRole.seeker);

    expect(state.activeRole, PlayerRole.seeker);
    expect(state.findingState.players['me']?.role, PlayerRole.seeker);
    expect(state.currentHiderFound, isFalse);
    expect(state.currentHiderFoundAt, isNull);
    expect(state.foundHiders, 0);
    expect(state.activeHiders, 15);
    expect(state.personallyFoundHiders, 0);
  });

}
