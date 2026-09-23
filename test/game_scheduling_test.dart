import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/domain/game_scheduling.dart';

void main() {
  final now = DateTime(2026, 9, 23, 14, 30);
  final rules = GameSchedulingRules(now);

  test('startdatum loopt van vandaag tot einde volgend kalenderjaar', () {
    expect(rules.firstAllowedDate, DateTime(2026, 9, 23));
    expect(rules.lastAllowedDate, DateTime(2027, 12, 31));
    expect(rules.clampDate(DateTime(2020)), DateTime(2026, 9, 23));
    expect(rules.clampDate(DateTime(2035)), DateTime(2027, 12, 31));
  });

  test('een verstreken of te ver toekomstig startmoment is ongeldig', () {
    expect(rules.isAllowedStart(DateTime(2026, 9, 23, 14)), isFalse);
    expect(rules.isAllowedStart(DateTime(2026, 9, 23, 15)), isTrue);
    expect(rules.isAllowedStart(DateTime(2028, 1, 1)), isFalse);
  });
}
