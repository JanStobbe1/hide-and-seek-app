import '../config/game_config.dart';
import 'models.dart';

enum HintBlockReason {
  cooldown,
  insufficientPoints,
  finalQuarter,
  zoneTooSmall,
}

class HintUseResult {
  const HintUseResult({
    required this.started,
    required this.points,
    required this.purchasedHints,
    this.reason,
  });
  final bool started;
  final int points;
  final int purchasedHints;
  final HintBlockReason? reason;
}

class HintState {
  HintState({
    required this.points,
    this.freeAvailable = true,
    this.purchasedHints = 0,
    this.lastUsed,
  });
  int points;
  bool freeAvailable;
  int purchasedHints;
  DateTime? lastUsed;
}

class HintService {
  const HintService({this.config = const GameConfig()});
  final GameConfig config;
  HintUseResult use({
    required HintState state,
    required DateTime now,
    required int quarter,
    required bool zoneLargeEnough,
  }) {
    HintBlockReason? block;
    if (state.lastUsed != null &&
        now.difference(state.lastUsed!) < config.hintCooldown)
      block = HintBlockReason.cooldown;
    if (quarter >= 3) block ??= HintBlockReason.finalQuarter;
    if (!zoneLargeEnough) block ??= HintBlockReason.zoneTooSmall;
    final cost = state.freeAvailable ? 0 : config.hintCost(quarter);
    if (state.points < cost) block ??= HintBlockReason.insufficientPoints;
    if (block != null)
      return HintUseResult(
        started: false,
        points: state.points,
        purchasedHints: state.purchasedHints,
        reason: block,
      );
    state.points -= cost;
    state.lastUsed = now;
    if (state.freeAvailable) {
      state.freeAvailable = false;
    } else {
      state.purchasedHints++;
    }
    return HintUseResult(
      started: true,
      points: state.points,
      purchasedHints: state.purchasedHints,
    );
  }

  int finalPoints(HintState state) =>
      state.points - state.purchasedHints * config.hintResultPenalty;
  Map<PlayerRole, Map<PlayerRole, int>> counts(Iterable<PlayerRole> roles) => {
    PlayerRole.seeker: {
      PlayerRole.hider: roles.where((r) => r == PlayerRole.hider).length,
    },
    PlayerRole.hider: {
      for (final role in PlayerRole.values)
        role: roles.where((r) => r == role).length,
    },
  };
}
