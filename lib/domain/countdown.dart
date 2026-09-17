class GameCountdown {
  const GameCountdown({required this.total, required this.remaining})
      : assert(remaining <= total);

  factory GameCountdown.start(Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(duration, 'duration', 'Must not be negative.');
    }
    return GameCountdown(total: duration, remaining: duration);
  }

  final Duration total;
  final Duration remaining;

  Duration get elapsed => total - remaining;
  bool get isFinished => remaining == Duration.zero;

  GameCountdown tick([Duration amount = const Duration(seconds: 1)]) {
    if (amount.isNegative) {
      throw ArgumentError.value(amount, 'amount', 'Must not be negative.');
    }
    if (isFinished || amount == Duration.zero) return this;
    final next = remaining - amount;
    return GameCountdown(
      total: total,
      remaining: next.isNegative ? Duration.zero : next,
    );
  }
}
