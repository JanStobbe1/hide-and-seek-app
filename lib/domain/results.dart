enum ResultTone { mostPositive, positive, neutral, negative, veryNegative, mostNegative }

abstract final class ResultService {
  static bool seekerTeamWon({required int foundHiders, required int totalHiders}) =>
      totalHiders > 0 && foundHiders / totalHiders >= .5;

  static ResultTone seekerTone({required int personallyFound, required int totalFound, required int totalHiders}) {
    if (personallyFound == 0) return ResultTone.mostNegative;
    final teamWon = seekerTeamWon(foundHiders: totalFound, totalHiders: totalHiders);
    final share = totalFound == 0 ? 0 : personallyFound / totalFound;
    if (share == 1) return ResultTone.mostPositive;
    if (share >= .5) return ResultTone.positive;
    if (teamWon && share <= .1) return ResultTone.neutral;
    if (!teamWon && share < .1) return ResultTone.veryNegative;
    return teamWon ? ResultTone.positive : ResultTone.negative;
  }

  static ResultTone hiderTone({required bool found, required Duration? foundAt, required Duration total, required int survivors}) {
    if (!found && survivors == 1) return ResultTone.mostPositive;
    if (!found) return ResultTone.positive;
    final ratio = (foundAt ?? Duration.zero).inMicroseconds / total.inMicroseconds;
    if (ratio >= .75) return ResultTone.positive;
    if (ratio < .25) return ResultTone.mostNegative;
    if (ratio < .5) return ResultTone.negative;
    return ResultTone.neutral;
  }
}
