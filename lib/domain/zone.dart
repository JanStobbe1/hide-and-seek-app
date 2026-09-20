import 'dart:math' as math;
import '../config/game_config.dart';
class Point2 { const Point2(this.x, this.y); final double x; final double y; double distanceTo(Point2 other) => math.sqrt(math.pow(x-other.x,2)+math.pow(y-other.y,2)); }
class CircleZone { const CircleZone({required this.center, required this.radius}); final Point2 center; final double radius; double get area => math.pi*radius*radius; bool contains(Point2 p) => center.distanceTo(p) <= radius; bool containsZone(CircleZone z) => center.distanceTo(z.center)+z.radius <= radius + 1e-9; double distanceOutside(Point2 p) => math.max(0.0, center.distanceTo(p)-radius); }
class ZoneService {
  const ZoneService({this.config=const GameConfig()}); final GameConfig config;
  List<Duration> shrinkStarts(Duration total) => [1,2,3].map((q)=> Duration(microseconds: total.inMicroseconds*q~/4)).toList();
  CircleZone candidate(CircleZone current, Point2 center) => CircleZone(center:center, radius:current.radius*math.sqrt(config.shrinkAreaFactor));
  CircleZone requireContained(CircleZone current, CircleZone proposed) { if (!current.containsZone(proposed)) throw ArgumentError('New zone must be fully contained.'); return proposed; }
}
class ZoneGpsState { int outsideMeasurements=0; bool confirmedOutside=false; DateTime? countdownStartedAt; bool eliminated=false; }
class ZoneGpsService {
  const ZoneGpsService({this.config=const GameConfig()}); final GameConfig config;
  Duration returnTime({required double distanceMeters, required double metersPerSecond, required Duration gameDuration}) {
    if (distanceMeters < 0 || metersPerSecond <= 0) throw ArgumentError('Invalid travel parameters.');
    final estimate=Duration(milliseconds:(distanceMeters/metersPerSecond*config.travelSafetyFactor*1000).round());
    final maximum=Duration(microseconds:(gameDuration.inMicroseconds*config.maximumReturnFraction).round());
    final effectiveMin=maximum < config.minimumReturnTime ? maximum : config.minimumReturnTime;
    if (estimate < effectiveMin) return effectiveMin; if (estimate > maximum) return maximum; return estimate;
  }
  void record(ZoneGpsState state,{required bool inside,required bool valid,required DateTime now,required Duration allowance}) {
    if (!valid || state.eliminated) return;
    if (inside) { state.outsideMeasurements=0; state.confirmedOutside=false; state.countdownStartedAt=null; return; }
    state.outsideMeasurements++;
    if (state.outsideMeasurements >= config.confirmationMeasurements) { state.confirmedOutside=true; state.countdownStartedAt ??= now; if (now.difference(state.countdownStartedAt!) > allowance) state.eliminated=true; }
  }
}
