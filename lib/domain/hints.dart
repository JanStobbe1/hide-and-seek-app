import 'dart:math' as math;

import '../config/app_config.dart';

class HintState {
  HintState({required this.points, this.freeHintAvailable = true});
  int points;
  bool freeHintAvailable;
  DateTime? lastUsedAt;
  int boughtHints = 0;
}

class HintDecision {
  const HintDecision({required this.allowed, this.cost = 0, this.reason});
  final bool allowed;
  final int cost;
  final String? reason;
}

class HintService {
  const HintService();

  int priceForQuarter(int quarter) {
    if (quarter < 1 || quarter > 4) throw RangeError.range(quarter, 1, 4);
    return (AppConfig.hintBaseCost * math.pow(AppConfig.hintQuarterMultiplier, quarter - 1)).ceil();
  }

  HintDecision use({required HintState state, required DateTime now, required int quarter, required bool zoneAllowsHints}) {
    if (state.lastUsedAt != null && now.difference(state.lastUsedAt!) < AppConfig.hintCooldown) {
      return const HintDecision(allowed: false, reason: 'cooldown');
    }
    if (!zoneAllowsHints || quarter == 4) {
      return const HintDecision(allowed: false, reason: 'blocked');
    }
    if (state.freeHintAvailable) {
      state.freeHintAvailable = false;
      state.lastUsedAt = now;
      return const HintDecision(allowed: true);
    }
    final cost = priceForQuarter(quarter);
    if (state.points < cost) {
      return const HintDecision(allowed: false, reason: 'insufficientPoints');
    }
    state.points -= cost;
    state.boughtHints++;
    state.lastUsedAt = now;
    return HintDecision(allowed: true, cost: cost);
  }

  int resultPenalty(HintState state) => state.boughtHints * AppConfig.hintResultPenalty;
}
