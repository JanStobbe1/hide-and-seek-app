import 'package:flutter/foundation.dart';

import 'data/mock_game_repository.dart';
import 'domain/countdown.dart';
import 'domain/game_engine.dart';
import 'domain/models.dart';
import 'domain/player_value_rules.dart';
import 'domain/profile_models.dart';

class AppState extends ChangeNotifier {
  AppState({
    MockGameRepository? repository,
    this.activeGameDuration = const Duration(minutes: 30),
  }) : repository = repository ?? MockGameRepository() {
    activeGame = ActiveGameState(
      countdown: GameCountdown.start(activeGameDuration),
    );
    _lastGameClockUpdate = DateTime.now();
  }
  final MockGameRepository repository;
  final Duration activeGameDuration;
  late ActiveGameState activeGame;
  late DateTime _lastGameClockUpdate;
  bool gameFinished = false;
  int gamesPlayed = 5;
  int wins = 3;
  int points = 840;
  String displayName = 'Arie';
  String profileAvatar = 'A';
  ThemePreference themePreference = ThemePreference.forest;
  PlayerMarker playerMarker = PlayerMarker.ghost;
  final List<FriendProfile> friends = const [
    FriendProfile(
      name: 'Mila',
      city: 'Almere',
      gamesPlayed: 12,
      gamesWon: 6,
      points: 1840,
    ),
    FriendProfile(
      name: 'Sam',
      city: 'Amsterdam',
      gamesPlayed: 8,
      gamesWon: 3,
      points: 1120,
    ),
    FriendProfile(
      name: 'Noa',
      city: 'Lelystad',
      gamesPlayed: 5,
      gamesWon: 2,
      points: 760,
    ),
  ];
  final Map<String, bool> privacy = {
    'Deel mijn naam': true,
    'Deel mijn leeftijd': false,
    'Deel mijn woonplaats': true,
    'Deel mijn foto': true,
    'Meld deelname aan eerdere tegenstanders': true,
    'Meld deelname aan eerdere vrienden': true,
  };

  void join(String id) {
    repository.join(id);
    notifyListeners();
  }

  void publish(Game game) {
    repository.publish(game);
    notifyListeners();
  }

  void foundPlayer() {
    activeGame = activeGame.playerFound();
    notifyListeners();
  }

  void useInvisibility() {
    activeGame = activeGame.useInvisibility();
    notifyListeners();
  }

  void tickActiveGame([Duration amount = const Duration(seconds: 1)]) {
    final next = activeGame.tick(amount);
    if (identical(next, activeGame)) return;
    activeGame = next;
    if (next.status == GameStatus.completed && !gameFinished) {
      gameFinished = true;
      gamesPlayed++;
    }
    notifyListeners();
  }

  void syncActiveGameClock([DateTime? timestamp]) {
    final now = timestamp ?? DateTime.now();
    if (now.isBefore(_lastGameClockUpdate)) return;
    final elapsed = now.difference(_lastGameClockUpdate);
    _lastGameClockUpdate = now;
    tickActiveGame(elapsed);
  }

  double playerValue(PlayerRole role) => DemoPlayerValueRules.calculate(
    role: role,
    elapsed: activeGame.elapsed,
    playersFound: activeGame.playersFound,
  );

  void setDisplayName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    displayName = trimmed;
    notifyListeners();
  }

  void setProfileAvatar(String value) {
    profileAvatar = value;
    notifyListeners();
  }

  void setThemePreference(ThemePreference value) {
    themePreference = value;
    notifyListeners();
  }

  void setPlayerMarker(PlayerMarker value) {
    playerMarker = value;
    notifyListeners();
  }

  void finishGame() {
    if (activeGame.status == GameStatus.completed) return;
    activeGame = activeGame.finish();
    gameFinished = true;
    gamesPlayed++;
    notifyListeners();
  }

  void setPrivacy(String key, bool value) {
    privacy[key] = value;
    notifyListeners();
  }

  void reset() {
    repository.reset();
    activeGame = ActiveGameState(
      countdown: GameCountdown.start(activeGameDuration),
    );
    _lastGameClockUpdate = DateTime.now();
    gameFinished = false;
    gamesPlayed = 5;
    wins = 3;
    points = 840;
    displayName = 'Arie';
    profileAvatar = 'A';
    themePreference = ThemePreference.forest;
    playerMarker = PlayerMarker.ghost;
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
