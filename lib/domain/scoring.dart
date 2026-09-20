import '../config/game_config.dart';
import 'models.dart';

class ScoringPlayer {
  const ScoringPlayer({
    required this.id,
    required this.role,
    required this.points,
    this.active = true,
  });
  final String id;
  final PlayerRole role;
  final int points;
  final bool active;
  ScoringPlayer copyWith({int? points, bool? active}) => ScoringPlayer(
    id: id,
    role: role,
    points: points ?? this.points,
    active: active ?? this.active,
  );
}

class FindingState {
  FindingState(Iterable<ScoringPlayer> players)
    : players = {for (final p in players) p.id: p};
  final Map<String, ScoringPlayer> players;
  final Set<String> processedEvents = {};
}

class FindingService {
  const FindingService({this.config = const GameConfig()});
  final GameConfig config;

  bool register({
    required FindingState state,
    required String eventId,
    required String finderId,
    required String hiderId,
  }) {
    if (state.processedEvents.contains(eventId)) return false;
    final finder = state.players[finderId];
    final hider = state.players[hiderId];
    if (finder == null ||
        hider == null ||
        !finder.active ||
        !hider.active ||
        finder.role != PlayerRole.seeker ||
        hider.role != PlayerRole.hider)
      return false;
    state.processedEvents.add(eventId);
    final value = hider.points;
    for (final entry in state.players.entries.toList()) {
      final player = entry.value;
      if (!player.active) continue;
      if (player.id == finderId) {
        state.players[entry.key] = player.copyWith(
          points:
              player.points +
              config.roundPoints(value * config.finderRewardRate),
        );
      } else if (player.role == PlayerRole.seeker) {
        state.players[entry.key] = player.copyWith(
          points:
              player.points +
              config.roundPoints(value * config.otherSeekerRewardRate),
        );
      } else if (player.id != hiderId) {
        state.players[entry.key] = player.copyWith(
          points: player.points + config.survivingHiderBonus,
        );
      }
    }
    state.players[hiderId] = hider.copyWith(active: false);
    return true;
  }
}
