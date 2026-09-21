import '../data/dutch_municipalities.dart';

abstract interface class LocationRepository {
  List<String> get countries;
  List<String> provincesFor(String country);
  List<String> citiesFor(String country, String province);
  List<String> neighbourhoodsFor(String country, String province, String city);
}

typedef _ProvinceLocations = Map<String, Map<String, List<String>>>;

Iterable<String> filterLocationOptions(Iterable<String> options, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return options;
  return options.where((option) => option.toLowerCase().contains(normalized));
}

class DemoLocationRepository implements LocationRepository {
  const DemoLocationRepository();

  static const Map<String, _ProvinceLocations> _locations = {
    'Nederland': {
      'Flevoland': {
        'Almere': ['Almere Stad', 'Almere Haven', 'Almere Buiten'],
        'Lelystad': ['Centrum', 'Haven', 'Warande'],
      },
      'Noord-Holland': {
        'Amsterdam': ['Centrum', 'Noord', 'West', 'Zuidoost'],
        'Haarlem': ['Centrum', 'Schalkwijk'],
      },
      'Utrecht': {
        'Utrecht': ['Binnenstad', 'Leidsche Rijn', 'Overvecht'],
        'Amersfoort': ['Centrum', 'Vathorst'],
      },
    },
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
  List<String> get countries => _locations.keys.toList(growable: false);

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
  List<String> neighbourhoodsFor(String country, String province, String city) {
    if (province == 'Alle' || city == 'Alle') return const ['Alle'];
    return _withAll(_locations[country]?[province]?[city]);
  }

  static List<String> _withAll(Iterable<String>? values) {
    return ['Alle', ...?values];
  }
}

class LocationSelection {
  const LocationSelection({
    this.country,
    this.province,
    this.city,
    this.neighbourhood,
  });

  final String? country;
  final String? province;
  final String? city;
  final String? neighbourhood;

  LocationSelection selectCountry(String? value) {
    return LocationSelection(country: value);
  }

  LocationSelection selectProvince(String? value) {
    return LocationSelection(
      country: country,
      province: value,
      city: value == 'Alle' ? 'Alle' : null,
      neighbourhood: value == 'Alle' ? 'Alle' : null,
    );
  }

  LocationSelection selectCity(String? value) {
    return LocationSelection(
      country: country,
      province: province,
      city: value,
      neighbourhood: value == 'Alle' ? 'Alle' : null,
    );
  }

  LocationSelection selectNeighbourhood(String? value) {
    return LocationSelection(
      country: country,
      province: province,
      city: city,
      neighbourhood: value,
    );
  }
}
