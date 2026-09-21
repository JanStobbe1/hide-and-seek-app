import 'dart:math' as math;

import '../config/app_config.dart';

class CircleZone {
  const CircleZone({required this.x, required this.y, required this.radius});
  final double x;
  final double y;
  final double radius;
  double get area => math.pi * radius * radius;

  bool containsZone(CircleZone other) {
    final centers =
        math.sqrt(math.pow(other.x - x, 2) + math.pow(other.y - y, 2));
    return centers + other.radius <= radius + 1e-9;
  }

  bool containsPoint(double pointX, double pointY) {
    final distance =
        math.sqrt(math.pow(pointX - x, 2) + math.pow(pointY - y, 2));
    return distance <= radius;
  }

  double distanceToBoundary(double pointX, double pointY) {
    final centerDistance =
        math.sqrt(math.pow(pointX - x, 2) + math.pow(pointY - y, 2));
    return math.max(0, centerDistance - radius);
  }
}

abstract final class ZoneRules {
  static CircleZone shrink(CircleZone current,
      {required double offsetX, required double offsetY}) {
    final next = CircleZone(
        x: current.x + offsetX,
        y: current.y + offsetY,
        radius: current.radius * math.sqrt(AppConfig.shrinkAreaFactor));
    if (!current.containsZone(next)) {
      throw ArgumentError('New zone must fit within current zone.');
    }
    return next;
  }

  static int shrinkPhase(Duration elapsed, Duration total) {
    if (total <= Duration.zero) throw ArgumentError.value(total);
    final ratio = elapsed.inMicroseconds / total.inMicroseconds;
    if (ratio >= .75) return 3;
    if (ratio >= .5) return 2;
    if (ratio >= .25) return 1;
    return 0;
  }

  static Duration returnTime(
      {required double distanceMeters,
      required double speedMetersPerSecond,
      required Duration gameDuration}) {
    if (distanceMeters < 0 ||
        speedMetersPerSecond <= 0 ||
        gameDuration <= Duration.zero) {
      throw ArgumentError('Invalid return-time input.');
    }
    final estimateSeconds =
        distanceMeters / speedMetersPerSecond * AppConfig.returnSafetyFactor;
    final minSeconds = AppConfig.minReturnTime.inSeconds.toDouble();
    final maxSeconds = gameDuration.inSeconds * AppConfig.maxReturnTimeFraction;
    final bounded = math.min(math.max(estimateSeconds, minSeconds), maxSeconds);
    return Duration(milliseconds: (bounded * 1000).round());
  }
}

class OutsideZoneTracker {
  OutsideZoneTracker(
      {this.requiredSamples = AppConfig.outsideConfirmationSamples});
  final int requiredSamples;
  int _outsideSamples = 0;
  DateTime? confirmedOutsideAt;

  bool update(
      {required bool inside, required bool reliable, required DateTime now}) {
    if (!reliable) return confirmedOutsideAt != null;
    if (inside) {
      _outsideSamples = 0;
      confirmedOutsideAt = null;
      return false;
    }
    _outsideSamples++;
    if (_outsideSamples >= requiredSamples) confirmedOutsideAt ??= now;
    return confirmedOutsideAt != null;
  }
}
