import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/domain/game_setup.dart';

void main() {
  test(
    'only complete and distinct sets of three or five questions are valid',
    () {
      expect(validateCustomQuestions(3, ['Een?', 'Twee?', 'Drie?']), isNull);
      expect(
        validateCustomQuestions(5, [
          'Een?',
          'Twee?',
          'Drie?',
          'Vier?',
          'Vijf?',
        ]),
        isNull,
      );
      expect(
        validateCustomQuestions(4, ['Een?', 'Twee?', 'Drie?', 'Vier?']),
        isNotNull,
      );
      expect(validateCustomQuestions(3, ['Een?', ' ', 'Drie?']), isNotNull);
      expect(
        validateCustomQuestions(3, ['Een?', ' een? ', 'Drie?']),
        isNotNull,
      );
      expect(
        validateCustomQuestions(3, ['x' * 161, 'Twee?', 'Drie?']),
        isNotNull,
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
