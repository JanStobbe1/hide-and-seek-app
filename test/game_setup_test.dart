import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/domain/game_setup.dart';

void main() {
  test(
    'only complete and distinct sets of three or five questions are valid',
    () {
      expect(
        validateCustomQuestions(3, [
          'Heb je een fiets?',
          'Draag je een jas?',
          'Heb je een hond?',
        ]),
        isNull,
      );
      expect(
        validateCustomQuestions(5, [
          'Heb je een fiets?',
          'Draag je een jas?',
          'Heb je een hond?',
          'Dit is vier?',
          'Dit is vijf?',
        ]),
        isNull,
      );
      expect(
        validateCustomQuestions(4, [
          'Heb je een fiets?',
          'Draag je een jas?',
          'Heb je een hond?',
          'Dit is vier?',
        ]),
        isNotNull,
      );
      expect(
        validateCustomQuestions(3, [
          'Heb je een fiets?',
          ' ',
          'Heb je een hond?',
        ]),
        isNotNull,
      );
      expect(
        validateCustomQuestions(3, [
          'Heb je een fiets?',
          ' heb je een fiets? ',
          'Heb je een hond?',
        ]),
        isNotNull,
      );
      expect(
        validateCustomQuestions(3, [
          'x' * 161,
          'Draag je een jas?',
          'Heb je een hond?',
        ]),
        isNotNull,
      );
      expect(
        validateCustomQuestions(3, [
          'Fiets?',
          'Draag je een jas?',
          'Heb je een hond?',
        ]),
        'Elke vraag moet minimaal twee woorden bevatten.',
      );
    },
  );
  test(
    'accepts real concave polygons and rejects crossed or degenerate borders',
    () {
      expect(
        validatePlayBoundary(const [
          AreaPoint(52, 5),
          AreaPoint(52, 6),
          AreaPoint(52.5, 5.5),
          AreaPoint(53, 6),
          AreaPoint(53, 5),
        ]),
        isNull,
      );
      expect(
        validatePlayBoundary(const [
          AreaPoint(52, 5),
          AreaPoint(53, 6),
          AreaPoint(52, 6),
          AreaPoint(53, 5),
        ]),
        isNotNull,
      );
      expect(
        validatePlayBoundary(const [
          AreaPoint(52, 5),
          AreaPoint(52, 5),
          AreaPoint(52, 5),
        ]),
        isNotNull,
      );
      expect(
        validatePlayBoundary(const [
          AreaPoint(52, 5),
          AreaPoint(53, 6),
          AreaPoint(54, 7),
        ]),
        isNotNull,
      );
      expect(validatePlayBoundary(const []), isNotNull);
    },
  );
}
