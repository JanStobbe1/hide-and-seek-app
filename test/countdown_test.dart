import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/domain/countdown.dart';

void main() {
  test(
    'countdown decreases from configured duration and never goes negative',
    () {
      final countdown = GameCountdown.start(const Duration(seconds: 3));

      final afterOneSecond = countdown.tick();
      final finished = afterOneSecond.tick(const Duration(seconds: 10));

      expect(afterOneSecond.remaining, const Duration(seconds: 2));
      expect(finished.remaining, Duration.zero);
      expect(finished.tick().remaining, Duration.zero);
    },
  );

  test('countdown rejects negative durations and ticks', () {
    expect(
      () => GameCountdown.start(const Duration(seconds: -1)),
      throwsArgumentError,
    );
    expect(
      () =>
          GameCountdown.start(const Duration(seconds: 3))
              .tick(const Duration(seconds: -1)),
      throwsArgumentError,
    );
  });
}
