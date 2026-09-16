import 'models.dart';

class ActiveGameState {
  const ActiveGameState({
    this.status = GameStatus.active,
    this.playersFound = 5,
    this.totalPlayers = 20,
    this.invisibilityAvailable = true,
  })  : assert(playersFound >= 0, 'Found players cannot be negative.'),
        assert(totalPlayers > 0, 'A game needs at least one player.'),
        assert(
          playersFound <= totalPlayers,
          'Found players cannot exceed total players.',
        );

  final GameStatus status;
  final int playersFound;
  final int totalPlayers;
  final bool invisibilityAvailable;

  ActiveGameState playerFound() {
    if (status != GameStatus.active || playersFound >= totalPlayers) {
      return this;
    }
    return ActiveGameState(
      status: status,
      playersFound: playersFound + 1,
      totalPlayers: totalPlayers,
      invisibilityAvailable: invisibilityAvailable,
    );
  }

  ActiveGameState finish() {
    if (status == GameStatus.completed) return this;
    return ActiveGameState(
      status: GameStatus.completed,
      playersFound: playersFound,
      totalPlayers: totalPlayers,
      invisibilityAvailable: invisibilityAvailable,
    );
  }

  ActiveGameState useInvisibility() {
    if (status != GameStatus.active || !invisibilityAvailable) return this;
    return ActiveGameState(
      status: status,
      playersFound: playersFound,
      totalPlayers: totalPlayers,
      invisibilityAvailable: false,
    );
  }
}
