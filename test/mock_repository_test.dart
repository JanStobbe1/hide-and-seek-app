import 'package:flutter_test/flutter_test.dart';
import 'package:verstobbertje/data/mock_game_repository.dart';

void main() {
  test('joining locally adds a game once and reset restores demo state', () {
    final repository = MockGameRepository();
    repository.join('epic');
    repository.join('epic');
    expect(repository.joinedGames, hasLength(1));
    expect(repository.joinedGames.single.participants, 21);
    repository.reset();
    expect(repository.joinedGames, isEmpty);
    expect(repository.availableGames.first.participants, 20);
  });
}
