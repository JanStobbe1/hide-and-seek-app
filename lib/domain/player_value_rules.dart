import 'models.dart';
import 'scoring.dart';

/// Centralized prototype rules for the displayed, simulated player value.
///
/// These constants are deliberately easy to replace when the actual game
/// economy has been designed. They are not a payout or real-money formula.
abstract final class DemoPlayerValueRules {
  static const double seekerBaseValue = 50;
  static const double hiderBaseValue = 100;

  static double calculate({
    required PlayerRole role,
    required Duration elapsed,
    required int playersFound,
    Duration total = const Duration(minutes: 30),
  }) {
    return switch (role) {
      PlayerRole.seeker => SeekerDecay.valueAt(
          startValue: seekerBaseValue,
          total: total,
          elapsed: elapsed,
        ),
      PlayerRole.hider => hiderBaseValue + playersFound * 10,
    };
  }
}
