import 'models.dart';

class ActiveGameState {
  const ActiveGameState({this.status = GameStatus.active, this.playersFound = 5, this.totalPlayers = 20, this.invisibilityAvailable = true});
  final GameStatus status;
  final int playersFound;
  final int totalPlayers;
  final bool invisibilityAvailable;

  ActiveGameState playerFound() {
    if (status != GameStatus.active || playersFound >= totalPlayers) return this;
    return ActiveGameState(status: status, playersFound: playersFound + 1, totalPlayers: totalPlayers, invisibilityAvailable: invisibilityAvailable);
  }

  ActiveGameState finish() => ActiveGameState(status: GameStatus.completed, playersFound: playersFound, totalPlayers: totalPlayers, invisibilityAvailable: invisibilityAvailable);

  ActiveGameState useInvisibility() => ActiveGameState(status: status, playersFound: playersFound, totalPlayers: totalPlayers, invisibilityAvailable: false);
}
