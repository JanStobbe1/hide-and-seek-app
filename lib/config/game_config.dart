import 'dart:math' as math;

enum PointRounding { nearest, floor, ceil }

/// Single source of truth for all configurable V1 game parameters.
class GameConfig {
  const GameConfig({
    this.joinGrace = const Duration(minutes: 5),
    this.shrinkDuration = const Duration(minutes: 5),
    this.shrinkAreaFactor = .95,
    this.questionReturnGrace = const Duration(seconds: 5),
    this.hintDuration = const Duration(seconds: 60),
    this.hintShrinkStart = const Duration(seconds: 30),
    this.hintCooldown = const Duration(minutes: 10),
    this.hintBaseCost = 5,
    this.hintQuarterIncrease = .2,
    this.hintResultPenalty = 1,
    this.rankValueIncrement = 5,
    this.finderRewardRate = .8,
    this.otherSeekerRewardRate = .2,
    this.survivingHiderBonus = 10,
    this.travelSafetyFactor = 1.5,
    this.minimumReturnTime = const Duration(minutes: 2),
    this.maximumReturnFraction = .1,
    this.confirmationMeasurements = 2,
    this.pointRounding = PointRounding.nearest,
  });

  final Duration joinGrace;
  final Duration shrinkDuration;
  final double shrinkAreaFactor;
  final Duration questionReturnGrace;
  final Duration hintDuration;
  final Duration hintShrinkStart;
  final Duration hintCooldown;
  final int hintBaseCost;
  final double hintQuarterIncrease;
  final int hintResultPenalty;
  final int rankValueIncrement;
  final double finderRewardRate;
  final double otherSeekerRewardRate;
  final int survivingHiderBonus;
  final double travelSafetyFactor;
  final Duration minimumReturnTime;
  final double maximumReturnFraction;
  final int confirmationMeasurements;
  final PointRounding pointRounding;

  int roundPoints(double value) => switch (pointRounding) {
        PointRounding.nearest => value.round(),
        PointRounding.floor => value.floor(),
        PointRounding.ceil => value.ceil(),
      };

  int hintCost(int quarter) => roundPoints(
        (hintBaseCost * math.pow(1 + hintQuarterIncrease, quarter.clamp(0, 3)))
            .toDouble(),
      );
}
