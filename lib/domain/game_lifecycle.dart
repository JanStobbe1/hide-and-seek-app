import '../config/app_config.dart';

enum LifecycleStatus { available, waiting, active, completed }

enum EndReason { timeExpired, allHidersFound, allSeekersEliminated }

class GameLifecycle {
  GameLifecycle({required this.startsAt, required this.duration});
  final DateTime startsAt;
  final Duration duration;
  LifecycleStatus status = LifecycleStatus.available;
  EndReason? endReason;
  bool _resultAutoShown = false;

  bool canJoin(DateTime now) => !now.isAfter(startsAt.add(AppConfig.joinGrace));

  bool finishIfNeeded(
      {required DateTime now,
      required int activeHiders,
      required int activeSeekers}) {
    if (status == LifecycleStatus.completed) return false;
    final EndReason? reason;
    if (!now.isBefore(startsAt.add(duration))) {
      reason = EndReason.timeExpired;
    } else if (activeHiders == 0) {
      reason = EndReason.allHidersFound;
    } else if (activeSeekers == 0) {
      reason = EndReason.allSeekersEliminated;
    } else {
      reason = null;
    }
    if (reason == null) return false;
    status = LifecycleStatus.completed;
    endReason = reason;
    return true;
  }

  bool takeAutomaticResultDisplay() {
    if (status != LifecycleStatus.completed || _resultAutoShown) return false;
    _resultAutoShown = true;
    return true;
  }
}
