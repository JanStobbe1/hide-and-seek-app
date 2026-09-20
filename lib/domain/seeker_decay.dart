import 'dart:math' as math;

class SeekerDecay {
  const SeekerDecay();
  static const factors = [1.0, 1.5, 2.25, 3.375];
  static const factorSum = 8.125;

  double ratePerMinute({
    required double startValue,
    required Duration gameDuration,
    required int quarter,
  }) {
    _validate(startValue, gameDuration);
    if (quarter < 0 || quarter > 3)
      throw RangeError.range(quarter, 0, 3, 'quarter');
    final quarterMinutes =
        gameDuration.inMicroseconds / Duration.microsecondsPerMinute / 4;
    return startValue / (quarterMinutes * factorSum) * factors[quarter];
  }

  double valueAt({
    required double startValue,
    required Duration gameDuration,
    required Duration elapsed,
  }) {
    _validate(startValue, gameDuration);
    final cappedMicros = elapsed.inMicroseconds.clamp(
      0,
      gameDuration.inMicroseconds,
    );
    final quarterMicros = gameDuration.inMicroseconds / 4;
    var loss = 0.0;
    for (var quarter = 0; quarter < 4; quarter++) {
      final start = quarter * quarterMicros;
      final minutes =
          ((cappedMicros - start).clamp(0, quarterMicros)) /
          Duration.microsecondsPerMinute;
      loss +=
          minutes *
          ratePerMinute(
            startValue: startValue,
            gameDuration: gameDuration,
            quarter: quarter,
          );
    }
    return math.max(0.0, startValue - loss);
  }

  void _validate(double startValue, Duration duration) {
    if (startValue < 0 || duration <= Duration.zero)
      throw ArgumentError(
        'Start value must be non-negative and duration positive.',
      );
  }
}
