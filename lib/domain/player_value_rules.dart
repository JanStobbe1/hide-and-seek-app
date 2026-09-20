import 'models.dart';

/// Centralized prototype rules for the displayed, simulated player value.
///
/// These constants are deliberately easy to replace when the actual game
/// economy has been designed. They are not a payout or real-money formula.
abstract final class DemoPlayerValueRules {
  static const double seekerBaseValue = 2;
  static const double valuePerPlayerFound = .75;
  static const double seekerDecayPerMinute = .03;
  static const double hiderBaseValue = 1;
  static const double hiderGrowthPerMinute = .04;
  static const double valuePerOtherHiderFound = .20;
  static const double minimumValue = .25;

  static double calculate({
    required PlayerRole role,
    required Duration elapsed,
    required int playersFound,
  }) {
    final elapsedMinutes = elapsed.inSeconds / 60;
    final value = switch (role) {
      PlayerRole.seeker =>
        seekerBaseValue +
            (playersFound * valuePerPlayerFound) -
            (elapsedMinutes * seekerDecayPerMinute),
      PlayerRole.hider =>
        hiderBaseValue +
            (elapsedMinutes * hiderGrowthPerMinute) +
            (playersFound * valuePerOtherHiderFound),
    };
    return value < minimumValue ? minimumValue : value;
  }
}
