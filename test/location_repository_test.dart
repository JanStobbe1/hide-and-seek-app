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


  test('multi location selection prunes invalid dependent choices', () {
    const repository = DemoLocationRepository();
    var selection = const MultiLocationSelection()
        .toggleCountry('Nederland', repository)
        .toggleProvince('Flevoland', repository)
        .toggleCity('Almere', repository)
        .toggleNeighbourhood('Almere Stad', repository);

    expect(selection.cities, contains('Almere'));
    expect(selection.neighbourhoods, contains('Almere Stad'));

    selection = selection
        .toggleProvince('Noord-Holland', repository)
        .toggleProvince('Flevoland', repository);

    expect(selection.provinces, {'Noord-Holland'});
    expect(selection.cities, isEmpty);
    expect(selection.neighbourhoods, isEmpty);
  });

  test('multi location selection supports multiple valid branches', () {
    const repository = DemoLocationRepository();
    final selection = const MultiLocationSelection()
        .toggleCountry('Nederland', repository)
        .toggleProvince('Flevoland', repository)
        .toggleProvince('Noord-Holland', repository)
        .toggleCity('Almere', repository)
        .toggleCity('Amsterdam', repository);

    expect(selection.provinces, containsAll(['Flevoland', 'Noord-Holland']));
    expect(selection.cities, containsAll(['Almere', 'Amsterdam']));
  });
