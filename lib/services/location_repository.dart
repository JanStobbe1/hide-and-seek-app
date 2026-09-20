abstract interface class LocationRepository {
  List<String> get countries;
  List<String> provincesFor(String country);
  List<String> citiesFor(String country, String province);
  bool containsCity(String country, String province, String city);
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

  LocationSelection selectCity(String? value, {LocationRepository? repository}) {
    if (value != null &&
        repository != null &&
        country != null &&
        province != null &&
        !repository.containsCity(country!, province!, value)) {
      return LocationSelection(country: country, province: province);
    }
    return LocationSelection(
      country: country,
      province: province,
      city: value,
      neighbourhood: value == 'Alle' ? 'Alle' : null,
    );
  }

  LocationSelection selectNeighbourhood(
    String? value, {
    LocationRepository? repository,
  }) {
    if (value != null &&
        repository != null &&
        country != null &&
        province != null &&
        city != null &&
        !repository.containsNeighbourhood(
          country!,
          province!,
          city!,
          value,
        )) {
      return LocationSelection(country: country, province: province, city: city);
    }
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
    this.countries = const {},
    this.provinces = const {},
    this.cities = const {},
    this.neighbourhoods = const {},
  });

  final Set<String> countries;
  final Set<String> provinces;
  final Set<String> cities;
  final Set<String> neighbourhoods;

  MultiLocationSelection toggleCountry(
    String value,
    LocationRepository repository,
  ) {
    final nextCountries = {...countries};
    nextCountries.contains(value)
        ? nextCountries.remove(value)
        : nextCountries.add(value);
    final validProvinces = {
      for (final country in nextCountries)
        ...repository.provincesFor(country).where((value) => value != 'Alle'),
    };
    return _prune(
      countries: nextCountries,
      provinces: provinces.intersection(validProvinces),
      repository: repository,
    );
  }

  MultiLocationSelection toggleProvince(
    String value,
    LocationRepository repository,
  ) {
    final valid = countries.any(
      (country) => repository.provincesFor(country).contains(value),
    );
    if (!valid || value == 'Alle') return this;
    final next = {...provinces};
    next.contains(value) ? next.remove(value) : next.add(value);
    return _prune(
      countries: countries,
      provinces: next,
      repository: repository,
    );
  }

  MultiLocationSelection toggleCity(
    String value,
    LocationRepository repository,
  ) {
    final valid = _countryProvincePairs(repository).any(
      (pair) => repository.containsCity(pair.$1, pair.$2, value),
    );
    if (!valid || value == 'Alle') return this;
    final next = {...cities};
    next.contains(value) ? next.remove(value) : next.add(value);
    return _prune(
      countries: countries,
      provinces: provinces,
      cities: next,
      repository: repository,
    );
  }

  MultiLocationSelection toggleNeighbourhood(
    String value,
    LocationRepository repository,
  ) {
    final valid = _countryProvinceCityTriples(repository).any(
      (triple) => repository.containsNeighbourhood(
        triple.$1,
        triple.$2,
        triple.$3,
        value,
      ),
    );
    if (!valid || value == 'Alle') return this;
    final next = {...neighbourhoods};
    next.contains(value) ? next.remove(value) : next.add(value);
    return MultiLocationSelection(
      countries: countries,
      provinces: provinces,
      cities: cities,
      neighbourhoods: next,
    );
  }

  MultiLocationSelection _prune({
    required Set<String> countries,
    required Set<String> provinces,
    Set<String>? cities,
    required LocationRepository repository,
  }) {
    final candidateCities = cities ?? this.cities;
    final validCities = <String>{};
    for (final country in countries) {
      for (final province in provinces) {
        if (!repository.provincesFor(country).contains(province)) continue;
        validCities.addAll(
          repository
              .citiesFor(country, province)
              .where((value) => value != 'Alle'),
        );
      }
    }
    final keptCities = candidateCities.intersection(validCities);
    final validNeighbourhoods = <String>{};
    for (final country in countries) {
      for (final province in provinces) {
        for (final city in keptCities) {
          if (!repository.containsCity(country, province, city)) continue;
          validNeighbourhoods.addAll(
            repository
                .neighbourhoodsFor(country, province, city)
                .where((value) => value != 'Alle'),
          );
        }
      }
    }
    return MultiLocationSelection(
      countries: countries,
      provinces: provinces,
      cities: keptCities,
      neighbourhoods: neighbourhoods.intersection(validNeighbourhoods),
    );
  }

  Iterable<(String, String)> _countryProvincePairs(
    LocationRepository repository,
  ) sync* {
    for (final country in countries) {
      for (final province in provinces) {
        if (repository.provincesFor(country).contains(province)) {
          yield (country, province);
        }
      }
    }
  }

  Iterable<(String, String, String)> _countryProvinceCityTriples(
    LocationRepository repository,
  ) sync* {
    for (final pair in _countryProvincePairs(repository)) {
      for (final city in cities) {
        if (repository.containsCity(pair.$1, pair.$2, city)) {
          yield (pair.$1, pair.$2, city);
        }
      }
    }
  }
}
