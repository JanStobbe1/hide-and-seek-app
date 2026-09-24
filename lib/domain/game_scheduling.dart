class GameSchedulingRules {
  const GameSchedulingRules(this.now);

  final DateTime now;

  DateTime get firstAllowedDate => DateTime(now.year, now.month, now.day);

  DateTime get lastAllowedDate => DateTime(now.year + 1, 12, 31);

  bool isAllowedStart(DateTime start) =>
      start.isAfter(now) && !start.isAfter(lastAllowedDate.endOfDay);

  DateTime clampDate(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    if (date.isBefore(firstAllowedDate)) return firstAllowedDate;
    if (date.isAfter(lastAllowedDate)) return lastAllowedDate;
    return date;
  }
}

extension on DateTime {
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999, 999);
}
