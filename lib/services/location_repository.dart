abstract interface class LocationRepository {
  List<String> get countries;
  List<String> provincesFor(String country);
  List<String> citiesFor(String country, String province);
  bool containsCity(String country, String province, String city);
  List<String> citiesForProvinces(String country, Iterable<String> provinces);
  List<String> neighbourhoodsFor(String country, String province, String city);
  bool containsNeighbourhood(
    String country,
    String province,
    String city,
    String neighbourhood,
  );
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
  List<String> provincesFor(String country) =>
      _withAll(_locations[country]?.keys);

  @override
  List<String> citiesFor(String country, String province) {
    if (province == 'Alle') return const ['Alle'];
    return _withAll(_locations[country]?[province]?.keys);
  }

  @override
  List<String> citiesForProvinces(
    String country,
    Iterable<String> provinces,
  ) {
    final selected = provinces.where((value) => value != 'Alle').toSet();
    if (selected.isEmpty) return const ['Alle'];
    final cities = <String>{};
    for (final province in selected) {
      cities.addAll(_locations[country]?[province]?.keys ?? const []);
    }
    return _withAll(cities);
  }

  bool cityBelongsToProvince(String country, String province, String city) =>
      city == 'Alle' || (_locations[country]?[province]?.containsKey(city) ?? false);

  @override
  bool containsCity(String country, String province, String city) =>
      city == 'Alle' || (_locations[country]?[province]?.containsKey(city) ?? false);

  @override
  List<String> neighbourhoodsFor(String country, String province, String city) {
    if (province == 'Alle' || city == 'Alle') return const ['Alle'];
    return _withAll(_locations[country]?[province]?[city]);
  }

  @override
  bool containsNeighbourhood(
    String country,
    String province,
    String city,
    String neighbourhood,
  ) =>
      neighbourhood == 'Alle' ||
      (_locations[country]?[province]?[city]?.contains(neighbourhood) ?? false);

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


class MultiLocationSelection {
  const MultiLocationSelection({
    this.country,
    this.provinces = const {},
    this.cities = const {},
    this.neighbourhoods = const {},
  });

  final String? country;
  final Set<String> provinces;
  final Set<String> cities;
  final Set<String> neighbourhoods;

  MultiLocationSelection selectCountry(String? value) =>
      MultiLocationSelection(country: value);

  MultiLocationSelection selectProvinces(
    Iterable<String> values,
    DemoLocationRepository repository,
  ) {
    final allowed = country == null
        ? <String>{}
        : repository.provincesFor(country!).toSet();
    final nextProvinces = values.where(allowed.contains).toSet();
    final allowedCities = country == null
        ? <String>{}
        : repository.citiesForProvinces(country!, nextProvinces).toSet();
    final nextCities = cities.where(allowedCities.contains).toSet();
    return MultiLocationSelection(
      country: country,
      provinces: nextProvinces,
      cities: nextCities,
      neighbourhoods: nextCities == cities ? neighbourhoods : const {},
    );
  }

  MultiLocationSelection selectCities(
    Iterable<String> values,
    DemoLocationRepository repository,
  ) {
    if (country == null) return this;
    final allowed = repository.citiesForProvinces(country!, provinces).toSet();
    final nextCities = values.where(allowed.contains).toSet();
    return MultiLocationSelection(
      country: country,
      provinces: provinces,
      cities: nextCities,
      neighbourhoods: nextCities == cities ? neighbourhoods : const {},
    );
  }
}
