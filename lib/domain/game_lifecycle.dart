import '../config/game_config.dart';
import 'models.dart';

class GameLifecycle {
  const GameLifecycle({this.config = const GameConfig()});
  final GameConfig config;
  bool canJoin({required DateTime startedAt, required DateTime now}) => !now.isAfter(startedAt.add(config.joinGrace));
  GameStatus statusFor({required Duration remaining, required int activeHiders, required int activeSeekers}) =>
      remaining <= Duration.zero || activeHiders == 0 || activeSeekers == 0 ? GameStatus.completed : GameStatus.active;
}

class ResultPresentationTracker {
  final Set<String> _shown = {};
  bool shouldAutoShow(String gameId) => _shown.add(gameId);
  bool canOpenManually(String gameId) => true;
}
