import 'package:flutter/foundation.dart';

import 'data/mock_game_repository.dart';
import 'domain/game_engine.dart';
import 'domain/models.dart';

class AppState extends ChangeNotifier {
  AppState({MockGameRepository? repository}) : repository = repository ?? MockGameRepository();
  final MockGameRepository repository;
  ActiveGameState activeGame = const ActiveGameState();
  bool gameFinished = false;
  int gamesPlayed = 5;
  int wins = 3;
  final Map<String, bool> privacy = {
    'Deel mijn naam': true,
    'Deel mijn leeftijd': false,
    'Deel mijn woonplaats': true,
    'Deel mijn foto': true,
    'Meld deelname aan eerdere tegenstanders': true,
    'Meld deelname aan eerdere vrienden': true,
  };

  void join(String id) { repository.join(id); notifyListeners(); }
  void publish(Game game) { repository.publish(game); notifyListeners(); }
  void foundPlayer() { activeGame = activeGame.playerFound(); notifyListeners(); }
  void useInvisibility() { activeGame = activeGame.useInvisibility(); notifyListeners(); }
  void finishGame() { activeGame = activeGame.finish(); gameFinished = true; gamesPlayed++; notifyListeners(); }
  void setPrivacy(String key, bool value) { privacy[key] = value; notifyListeners(); }
  void reset() {
    repository.reset();
    activeGame = const ActiveGameState();
    gameFinished = false;
    gamesPlayed = 5;
    wins = 3;
    privacy
      ..['Deel mijn naam'] = true
      ..['Deel mijn leeftijd'] = false
      ..['Deel mijn woonplaats'] = true
      ..['Deel mijn foto'] = true
      ..['Meld deelname aan eerdere tegenstanders'] = true
      ..['Meld deelname aan eerdere vrienden'] = true;
    notifyListeners();
  }
}
