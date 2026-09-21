import 'package:flutter_test/flutter_test.dart';
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
    expect(
      repository.neighbourhoodsFor('Nederland', 'Noord-Holland', 'Amsterdam'),
      contains('Centrum'),
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
  });

  test('municipalities without demo neighbourhoods still allow all', () {
    expect(
      repository.neighbourhoodsFor('Nederland', 'Gelderland', 'Arnhem'),
      ['Alle'],
    );
  });

  test('changing a parent clears incompatible children', () {
    const initial = LocationSelection(
      country: 'Nederland',
      province: 'Flevoland',
      city: 'Almere',
      neighbourhood: 'Almere Stad',
    );

    final changedProvince = initial.selectProvince('Noord-Holland');
    final allProvince = initial.selectProvince('Alle');

    expect(changedProvince.city, isNull);
    expect(changedProvince.neighbourhood, isNull);
    expect(allProvince.city, 'Alle');
    expect(allProvince.neighbourhood, 'Alle');
  });

  test('type filtering limits location choices case-insensitively', () {
    final filtered = filterLocationOptions(
      repository.citiesFor('Nederland', 'Noord-Holland'),
      'dam',
    );

    expect(filtered, ['Amsterdam']);
  });
}
