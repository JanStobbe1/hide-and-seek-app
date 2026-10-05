import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/app_state.dart';
import 'package:verstobbertje/domain/models.dart';

void main() {
  test('demo opens as Testuser 1 with the intended active game examples', () {
    final state = AppState(demoMode: true);
    addTearDown(state.dispose);

    expect(state.displayName, 'Testuser 1');
    expect(state.profileCity, 'Almere');
    expect(state.gamesPlayed, 5);
    expect(state.wins, 3);

    final activeGames = state.repository.joinedGames
        .where((game) => game.status == GameStatus.active)
        .toList();

    expect(activeGames, hasLength(4));
    expect(
      activeGames.map((game) => game.id),
      containsAll([
        'demo-powers-classic',
        'demo-no-powers',
        'demo-everyone-hunts',
        'demo-testuser-seeker',
      ]),
    );

    final powersGame =
        activeGames.firstWhere((game) => game.id == 'demo-powers-classic');
    final noPowersGame =
        activeGames.firstWhere((game) => game.id == 'demo-no-powers');
    final everyoneHunts =
        activeGames.firstWhere((game) => game.id == 'demo-everyone-hunts');
    final seekerGame =
        activeGames.firstWhere((game) => game.id == 'demo-testuser-seeker');

    expect(powersGame.rules.stobbePowersEnabled, isTrue);
    expect(noPowersGame.rules.stobbePowersEnabled, isFalse);
    expect(everyoneHunts.rules.gameType, GameType.everyoneHunts);
    expect(seekerGame.rules.gameType, GameType.classic);
    expect(seekerGame.rules.seekersCount, 2);
    expect(seekerGame.description, contains('Testuser 1 is zoeker'));
    expect(seekerGame.description, contains('Mila'));
  });
}
