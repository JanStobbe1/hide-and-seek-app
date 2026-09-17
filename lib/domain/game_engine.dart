
import 'countdown.dart';

import 'models.dart';

class ActiveGameState {
  const ActiveGameState({
    this.status = GameStatus.active,
    this.playersFound = 5,
    this.totalPlayers = 20,
    this.invisibilityAvailable = true,

    this.countdown = const GameCountdown(
      total: Duration(minutes: 30),
      remaining: Duration(minutes: 30),
    ),

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

  final GameCountdown countdown;

  Duration get elapsed => countdown.elapsed;


  ActiveGameState playerFound() {
    if (status != GameStatus.active || playersFound >= totalPlayers) {
      return this;
    }
    return ActiveGameState(
      status: status,
      playersFound: playersFound + 1,
      totalPlayers: totalPlayers,
      invisibilityAvailable: invisibilityAvailable,

      countdown: countdown,

    );
  }

  ActiveGameState finish() {
    if (status == GameStatus.completed) return this;
    return ActiveGameState(
      status: GameStatus.completed,
      playersFound: playersFound,
      totalPlayers: totalPlayers,
      invisibilityAvailable: invisibilityAvailable,

      countdown: countdown,

    );
  }

  ActiveGameState useInvisibility() {
    if (status != GameStatus.active || !invisibilityAvailable) return this;
    return ActiveGameState(
      status: status,
      playersFound: playersFound,
      totalPlayers: totalPlayers,
      invisibilityAvailable: false,

      countdown: countdown,
    );
  }

  ActiveGameState tick([Duration amount = const Duration(seconds: 1)]) {
    if (status != GameStatus.active || countdown.isFinished) return this;
    final nextCountdown = countdown.tick(amount);
    return ActiveGameState(
      status: nextCountdown.isFinished ? GameStatus.completed : status,
      playersFound: playersFound,
      totalPlayers: totalPlayers,
      invisibilityAvailable: invisibilityAvailable,
      countdown: nextCountdown,

    );
  }
}
