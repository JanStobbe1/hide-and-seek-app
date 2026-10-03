import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/game_setup.dart';
import '../domain/models.dart';

class AreaLookup {
  AreaLookup({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final Map<String, List<AreaPoint>> _cache = {};

  void dispose() => _client.close();

  Future<List<AreaPoint>> find(SearchArea area) async {
    final places = area.neighbourhood != 'Alle'
        ? area.neighbourhood.split(', ')
        : area.city != 'Alle'
            ? area.city.split(', ')
            : <String>[];
    final queries = (places.isEmpty ? [''] : places)
        .map(
          (place) => [
            ...place.split(' › ').reversed.where((p) => p.isNotEmpty),
            if (area.province != 'Alle') area.province,
            area.country,
          ].join(', '),
        )
        .toSet();
    if (queries.length > 12) {
      throw const FormatException(
        'Kies maximaal 12 plaatsen of teken zelf je speelgebied.',
      );
    }
    final points = <AreaPoint>[];
    for (final query in queries) {
      if (_cache.containsKey(query)) {
        points.addAll(_cache[query]!);
        continue;
      }
      final response = await _client
          .get(
            Uri.https('photon.komoot.io', '/api/', {'q': query, 'limit': '1'}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw const FormatException(
          'Locatie zoeken lukt nu niet. Probeer opnieuw of teken zelf.',
        );
      }
      final features = (jsonDecode(response.body)
          as Map<String, dynamic>)['features'] as List<dynamic>;
      if (features.isEmpty) {
        throw FormatException(
          'Geen locatie gevonden voor $query. Teken zelf het gebied.',
        );
      }
      final feature = features.first as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>;
      final country = area.country == 'België' ? 'BE' : 'NL';
      if (properties['countrycode'] != country) {
        throw FormatException(
          'Geen passende locatie gevonden voor $query. Teken zelf het gebied.',
        );
      }
      final extent = properties['extent'];
      if (extent is! List || extent.length != 4) {
        throw FormatException(
          'Geen gebiedsgrenzen gevonden voor $query. Teken zelf het gebied.',
        );
      }
      final box = [
        AreaPoint((extent[3] as num).toDouble(), (extent[0] as num).toDouble()),
        AreaPoint((extent[1] as num).toDouble(), (extent[2] as num).toDouble()),
      ];
      _cache[query] = box;
      points.addAll(box);
    }
    final south = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final north = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final west = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final east = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    // A starting rectangle enclosing the locations, not an administrative border.
    return [
      AreaPoint(south, west),
      AreaPoint(south, east),
      AreaPoint(north, east),
      AreaPoint(north, west),
    ];
  }
}
