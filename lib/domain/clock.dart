abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

class FakeClock implements Clock {
  FakeClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
  void advance(Duration amount) => current = current.add(amount);
}
