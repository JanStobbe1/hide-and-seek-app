import 'dart:math' as math;

class AreaPoint {
  const AreaPoint(this.latitude, this.longitude);
  final double latitude;
  final double longitude;

  List<double> toJson() => [latitude, longitude];
  static AreaPoint fromJson(List<dynamic> value) =>
      AreaPoint((value[0] as num).toDouble(), (value[1] as num).toDouble());
}

/// Vertices are stored in walking order, without repeating the first point.
String? validatePlayBoundary(List<AreaPoint> points) {
  if (points.length < 3 || points.length > 32) {
    return 'Kies 3 tot 32 hoekpunten voor het speelgebied.';
  }
  for (final point in points) {
    if (!point.latitude.isFinite ||
        !point.longitude.isFinite ||
        point.latitude.abs() > 85 ||
        point.longitude.abs() > 180) {
      return 'Een hoekpunt ligt buiten de kaart.';
    }
  }
  double cross(AreaPoint a, AreaPoint b, AreaPoint c) =>
      (b.longitude - a.longitude) * (c.latitude - a.latitude) -
      (b.latitude - a.latitude) * (c.longitude - a.longitude);
  bool onSegment(AreaPoint a, AreaPoint b, AreaPoint p) =>
      cross(a, b, p).abs() < 1e-12 &&
      p.longitude >= math.min(a.longitude, b.longitude) &&
      p.longitude <= math.max(a.longitude, b.longitude) &&
      p.latitude >= math.min(a.latitude, b.latitude) &&
      p.latitude <= math.max(a.latitude, b.latitude);
  var twiceArea = 0.0;
  final origin = points.first;
  for (var i = 0; i < points.length; i++) {
    final a = points[i], b = points[(i + 1) % points.length];
    if (a.latitude == b.latitude && a.longitude == b.longitude) {
      return 'Kies verschillende hoekpunten.';
    }
    twiceArea += cross(origin, a, b);
    for (var j = i + 1; j < points.length; j++) {
      if (j == i + 1 || (i == 0 && j == points.length - 1)) continue;
      final c = points[j], d = points[(j + 1) % points.length];
      if ((cross(a, b, c) * cross(a, b, d) < 0 &&
              cross(c, d, a) * cross(c, d, b) < 0) ||
          onSegment(a, b, c) ||
          onSegment(a, b, d) ||
          onSegment(c, d, a) ||
          onSegment(c, d, b)) {
        return 'De grens mag zichzelf niet kruisen. Teken de punten op volgorde.';
      }
    }
  }
  if (twiceArea.abs() < 1e-10) return 'Het speelgebied is te klein.';
  return null;
}

String? validateCustomQuestions(int count, List<String> questions) {
  if (count != 3 && count != 5) return 'Kies 3 of 5 vragen.';
  if (questions.length != count ||
      questions.any((q) => q.trim().isEmpty || q.trim().length > 160)) {
    return 'Vul alle $count ja/nee-vragen in (maximaal 160 tekens per vraag).';
  }
  if (questions.any((q) => q.trim().split(RegExp(r'\s+')).length < 2)) {
    return 'Elke vraag moet minimaal twee woorden bevatten.';
  }
  if (questions.map((q) => q.trim().toLowerCase()).toSet().length != count) {
    return 'Stel verschillende vragen.';
  }
  return null;
}
