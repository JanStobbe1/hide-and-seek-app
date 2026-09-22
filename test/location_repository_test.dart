import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/data/dutch_neighbourhoods.dart';
import 'package:verstobbertje/services/location_repository.dart';

void main() {
  const repository = DemoLocationRepository();

  test('location options follow the selected hierarchy', () {
    expect(repository.countries.first, 'Nederland');
    expect(repository.countries, isNot(contains('Alle')));
    expect(repository.provincesFor('Nederland').first, 'Alle');
    expect(
      repository.citiesFor('Nederland', 'Noord-Holland'),
      contains('Amsterdam'),
    );

    final districts = repository.districtsFor(
      'Nederland',
      'Noord-Holland',
      ['Amsterdam'],
    );
    expect(districts, contains('Amsterdam › Aetsveld/Oostelijke Vechtoever'));
    expect(
      repository.neighbourhoodsFor(
        'Nederland',
        'Noord-Holland',
        ['Amsterdam › Aetsveld/Oostelijke Vechtoever'],
      ),
      contains('Amsterdam › Aetsveld/Oostelijke Vechtoever › Aetsveld-Noord'),
    );
  });

  test('all Dutch provinces and 342 municipalities are available', () {
    final provinces = repository.provincesFor('Nederland');
    expect(provinces.length, 13);
    expect(
        provinces,
        containsAll(<String>[
          'Drenthe',
          'Flevoland',
          'Friesland',
          'Gelderland',
          'Groningen',
          'Limburg',
          'Noord-Brabant',
          'Noord-Holland',
          'Overijssel',
          'Utrecht',
          'Zeeland',
          'Zuid-Holland',
        ]));
    final municipalityCount = provinces
        .where((province) => province != 'Alle')
        .map((province) =>
            repository.citiesFor('Nederland', province).length - 1)
        .fold<int>(0, (total, count) => total + count);
    expect(municipalityCount, 342);
    expect(dutchDistrictsAndNeighbourhoods.length, 342);
  });

  test('multiple municipalities in one province can be selected together', () {
    const initial = LocationSelection(
      country: 'Nederland',
      province: 'Noord-Holland',
    );
    final selected = initial.selectCities(['Amsterdam', 'Haarlemmermeer']);

    expect(selected.cities, ['Amsterdam', 'Haarlemmermeer']);
    expect(
      repository.districtsFor(
        'Nederland',
        'Noord-Holland',
        selected.cities,
      ),
      containsAll([
        'Amsterdam › Aetsveld/Oostelijke Vechtoever',
        'Haarlemmermeer › Aalsmeerderbrug/ Oude Meer/ Rozenburg / Schiphol Rijk',
      ]),
    );
  });

  test('all is exclusive and changing a parent clears descendants', () {
    const initial = LocationSelection(
      country: 'Nederland',
      province: 'Flevoland',
      cities: ['Almere'],
      districts: ['Almere › Almere Stad'],
      neighbourhoods: ['Almere › Almere Stad › Centrum Almere Stad'],
    );

    final allCities = initial.selectCities(['Almere', 'Alle']);
    final changedProvince = initial.selectProvince('Noord-Holland');

    expect(allCities.cities, ['Alle']);
    expect(allCities.districts, ['Alle']);
    expect(allCities.neighbourhoods, ['Alle']);
    expect(changedProvince.cities, isEmpty);
    expect(changedProvince.districts, isEmpty);
    expect(changedProvince.neighbourhoods, isEmpty);
  });

  test('type filtering limits location choices case-insensitively', () {
    final filtered = filterLocationOptions(
      repository.citiesFor('Nederland', 'Noord-Holland'),
      'dam',
    );

    expect(filtered, ['Amsterdam', 'Edam-Volendam']);
  });

  group('natural introduction location', () {
    test('uses only the deepest explicitly selected level', () {
      expect(
        introductionLocationLabel(
          const LocationSelection(
            country: 'Nederland',
            province: 'Flevoland',
            cities: ['Almere'],
            districts: ['Almere › Filmwijk'],
            neighbourhoods: [
              'Almere › Filmwijk › Filmwijk Noord',
              'Almere › Filmwijk › Filmwijk Midden',
            ],
          ),
        ),
        'Filmwijk Noord en Filmwijk Midden',
      );
    });

    test('falls back through all selections to the relevant parent', () {
      expect(
        introductionLocationLabel(
          const LocationSelection(
            country: 'Nederland',
            province: 'Noord-Holland',
            cities: ['Amsterdam'],
            districts: ['Alle'],
            neighbourhoods: ['Alle'],
          ),
        ),
        'Amsterdam',
      );
      expect(
        introductionLocationLabel(
          const LocationSelection(
            country: 'Nederland',
            province: 'Noord-Holland',
            cities: ['Alle'],
            districts: ['Alle'],
            neighbourhoods: ['Alle'],
          ),
        ),
        'Noord-Holland',
      );
      expect(
        introductionLocationLabel(
          const LocationSelection(
            country: 'Nederland',
            province: 'Alle',
            cities: ['Alle'],
            districts: ['Alle'],
            neighbourhoods: ['Alle'],
          ),
        ),
        'Nederland',
      );
    });

    test('joins up to three places naturally and summarizes larger lists', () {
      expect(
        introductionLocationLabel(
          const LocationSelection(
            country: 'Nederland',
            province: 'Noord-Holland',
            cities: ['Amsterdam', 'Haarlemmermeer'],
          ),
        ),
        'Amsterdam en Haarlemmermeer',
      );
      expect(
        introductionLocationLabel(
          const LocationSelection(
            country: 'Nederland',
            province: 'Noord-Holland',
            cities: ['Amsterdam', 'Haarlem', 'Zandvoort', 'Aalsmeer'],
          ),
        ),
        'Noord-Holland',
      );
      expect(
        introductionLocationLabel(
          const LocationSelection(
            country: 'Nederland',
            province: 'Flevoland',
            cities: ['Almere'],
            districts: [
              'Almere › Filmwijk',
              'Almere › Parkwijk',
              'Almere › Waterwijk',
              'Almere › Verzetswijk',
            ],
          ),
        ),
        'Almere',
      );
    });
  });
}
