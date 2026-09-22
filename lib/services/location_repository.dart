import '../data/dutch_municipalities.dart';
import '../data/dutch_neighbourhoods.dart';

abstract interface class LocationRepository {
  List<String> get countries;
  List<String> provincesFor(String country);
  List<String> citiesFor(String country, String province);
  List<String> districtsFor(
    String country,
    String province,
    Iterable<String> cities,
  );
  List<String> neighbourhoodsFor(
    String country,
    String province,
    Iterable<String> districts,
  );
}

typedef _ProvinceLocations = Map<String, Map<String, List<String>>>;

const locationSeparator = ' › ';

Iterable<String> filterLocationOptions(Iterable<String> options, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return options;
  return options.where((option) => option.toLowerCase().contains(normalized));
}

class DemoLocationRepository implements LocationRepository {
  const DemoLocationRepository();

  static const Map<String, _ProvinceLocations> _locations = {
    'België': {
      'Antwerpen': {
        'Antwerpen': ['Centrum', 'Berchem'],
        'Mechelen': ['Centrum', 'Nekkerspoel'],
      },
      'Vlaams-Brabant': {
        'Leuven': ['Centrum', 'Heverlee'],
      },
    },
  };

  @override
  List<String> get countries => ['Nederland', ..._locations.keys];

  @override
  List<String> provincesFor(String country) => _withAll(country == 'Nederland'
      ? dutchMunicipalitiesByProvince.keys
      : _locations[country]?.keys);

  @override
  List<String> citiesFor(String country, String province) {
    if (province == 'Alle') return const ['Alle'];
    if (country == 'Nederland') {
      return _withAll(dutchMunicipalitiesByProvince[province]);
    }
    return _withAll(_locations[country]?[province]?.keys);
  }

  @override
  List<String> districtsFor(
    String country,
    String province,
    Iterable<String> cities,
  ) {
    if (province == 'Alle' || cities.contains('Alle')) return const ['Alle'];
    final result = <String>['Alle'];
    for (final city in cities) {
      final districts = country == 'Nederland'
          ? dutchDistrictsAndNeighbourhoods[city]?.keys
          : _locations[country]?[province]?[city];
      if (districts == null) continue;
      result.addAll(
        districts.map((district) => '$city$locationSeparator$district'),
      );
    }
    return result;
  }

  @override
  List<String> neighbourhoodsFor(
    String country,
    String province,
    Iterable<String> districts,
  ) {
    if (province == 'Alle' || districts.contains('Alle')) {
      return const ['Alle'];
    }
    final result = <String>['Alle'];
    for (final qualifiedDistrict in districts) {
      final parts = qualifiedDistrict.split(locationSeparator);
      if (parts.length != 2) continue;
      final city = parts.first;
      final district = parts.last;
      Iterable<String>? neighbourhoods;
      if (country == 'Nederland') {
        neighbourhoods = dutchDistrictsAndNeighbourhoods[city]?[district];
      } else {
        neighbourhoods = _locations[country]?[province]?[city];
      }
      if (neighbourhoods == null) continue;
      result.addAll(
        neighbourhoods.map(
          (neighbourhood) =>
              '$qualifiedDistrict$locationSeparator$neighbourhood',
        ),
      );
    }
    return result;
  }

  static List<String> _withAll(Iterable<String>? values) {
    return ['Alle', ...?values];
  }
}

class LocationSelection {
  const LocationSelection({
    this.country,
    this.province,
    this.cities = const [],
    this.districts = const [],
    this.neighbourhoods = const [],
  });

  final String? country;
  final String? province;
  final List<String> cities;
  final List<String> districts;
  final List<String> neighbourhoods;

  LocationSelection selectCountry(String? value) {
    return LocationSelection(country: value);
  }

  LocationSelection selectProvince(String? value) {
    return LocationSelection(
      country: country,
      province: value,
      cities: value == 'Alle' ? const ['Alle'] : const [],
      districts: value == 'Alle' ? const ['Alle'] : const [],
      neighbourhoods: value == 'Alle' ? const ['Alle'] : const [],
    );
  }

  LocationSelection selectCities(Iterable<String> values) {
    final selected = _normalize(values);
    return LocationSelection(
      country: country,
      province: province,
      cities: selected,
      districts: selected.contains('Alle') ? const ['Alle'] : const [],
      neighbourhoods: selected.contains('Alle') ? const ['Alle'] : const [],
    );
  }

  LocationSelection selectDistricts(Iterable<String> values) {
    final selected = _normalize(values);
    return LocationSelection(
      country: country,
      province: province,
      cities: cities,
      districts: selected,
      neighbourhoods: selected.contains('Alle') ? const ['Alle'] : const [],
    );
  }

  LocationSelection selectNeighbourhoods(Iterable<String> values) {
    return LocationSelection(
      country: country,
      province: province,
      cities: cities,
      districts: districts,
      neighbourhoods: _normalize(values),
    );
  }

  static List<String> _normalize(Iterable<String> values) {
    final unique = values.toSet().toList(growable: false);
    return unique.contains('Alle') ? const ['Alle'] : unique;
  }
}
