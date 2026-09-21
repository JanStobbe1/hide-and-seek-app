import '../config/app_config.dart';

enum ScoreRole { seeker, hider }

class ParticipantScore {
  ParticipantScore({required this.id, required this.role, required this.value});
  final String id;
  final ScoreRole role;
  double value;
  bool active = true;
}

class FindEvent {
  const FindEvent(
      {required this.id, required this.finderId, required this.hiderId});
  final String id;
  final String finderId;
  final String hiderId;
}

class FindOutcome {
  const FindOutcome({required this.applied, required this.deltas});
  final bool applied;
  final Map<String, double> deltas;
}

class ScoringService {
  final Set<String> _processedFinds = {};

  FindOutcome registerFind(
      FindEvent event, Map<String, ParticipantScore> players) {
    if (_processedFinds.contains(event.id)) {
      return const FindOutcome(applied: false, deltas: {});
    }
    final finder = players[event.finderId];
    final hider = players[event.hiderId];
    if (finder == null ||
        hider == null ||
        !finder.active ||
        !hider.active ||
        finder.role != ScoreRole.seeker ||
        hider.role != ScoreRole.hider) {
      return const FindOutcome(applied: false, deltas: {});
    }
    _processedFinds.add(event.id);
    final hiderValue = hider.value;
    final deltas = <String, double>{};
    void reward(ParticipantScore player, double amount) {
      player.value += amount;
      deltas[player.id] = amount;
    }

    reward(finder, hiderValue * AppConfig.finderRewardRate);
    for (final player in players.values) {
      if (!player.active || player.id == finder.id) continue;
      if (player.role == ScoreRole.seeker) {
        reward(player, hiderValue * AppConfig.otherSeekerRewardRate);
      } else if (player.id != hider.id) {
        reward(player, AppConfig.survivingHiderBonus);
      }
    }
    hider.active = false;
    return FindOutcome(applied: true, deltas: Map.unmodifiable(deltas));
  }
}

abstract final class SeekerDecay {
  static const _factors = [1.0, 1.5, 2.25, 3.375];
  static const _factorSum = 8.125;

  static double valueAt(
      {required double startValue,
      required Duration total,
      required Duration elapsed}) {
    if (startValue < 0 || total <= Duration.zero || elapsed.isNegative) {
      throw ArgumentError('Values and durations must be valid.');
    }
    final capped = elapsed > total ? total : elapsed;
    final quarterMicros = total.inMicroseconds / 4;
    final base = startValue / (quarterMicros * _factorSum);
    var remaining = capped.inMicroseconds.toDouble();
    var loss = 0.0;
    for (final factor in _factors) {
      final used = remaining > quarterMicros ? quarterMicros : remaining;
      loss += used * base * factor;
      remaining -= used;
      if (remaining <= 0) break;
    }
    final value = startValue - loss;
    return value <= 1e-9 ? 0 : value;
  }

  static double startValue({required double base, required int rankSteps}) {
    if (base < 0 || rankSteps < 0) throw ArgumentError('Invalid start value.');
    return base + rankSteps * AppConfig.rankStartValueIncrement;
  }
}
