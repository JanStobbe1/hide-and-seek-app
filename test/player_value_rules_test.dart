import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/domain/models.dart';
import 'package:verstobbertje/domain/player_value_rules.dart';

void main() {
  test('seeker elapsed value is independent of UI find counters', () {
    final before = DemoPlayerValueRules.calculate(
      role: PlayerRole.seeker,
      elapsed: const Duration(minutes: 5),
      playersFound: 2,
    );
    final after = DemoPlayerValueRules.calculate(
      role: PlayerRole.seeker,
      elapsed: const Duration(minutes: 5),
      playersFound: 3,
    );

    expect(after, before);
  });

  test('seeker value falls over time and hider value rises', () {
    final seekerEarly = DemoPlayerValueRules.calculate(
      role: PlayerRole.seeker,
      elapsed: Duration.zero,
      playersFound: 2,
    );
    final seekerLate = DemoPlayerValueRules.calculate(
      role: PlayerRole.seeker,
      elapsed: const Duration(minutes: 10),
      playersFound: 2,
    );
    final hiderEarly = DemoPlayerValueRules.calculate(
      role: PlayerRole.hider,
      elapsed: Duration.zero,
      playersFound: 2,
    );
    final hiderLate = DemoPlayerValueRules.calculate(
      role: PlayerRole.hider,
      elapsed: const Duration(minutes: 10),
      playersFound: 3,
    );

    expect(seekerLate, lessThan(seekerEarly));
    expect(hiderLate, greaterThan(hiderEarly));
  });
}
