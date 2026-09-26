import 'package:flutter/foundation.dart';

import 'data/backend_api_client.dart';
import 'data/mock_game_repository.dart';
import 'domain/countdown.dart';
import 'domain/game_engine.dart';
import 'domain/game_lifecycle.dart';
import 'domain/hints.dart';
import 'domain/models.dart';
import 'domain/player_value_rules.dart';
import 'domain/private_questions.dart';
import 'domain/profile_models.dart';
import 'domain/profile_validation.dart';
import 'domain/scoring.dart';
import 'domain/stobbe_powers.dart';
import 'domain/zones.dart';

class AppState extends ChangeNotifier {
  AppState({
    MockGameRepository? repository,
    this.activeGameDuration = const Duration(minutes: 30),
    this.backendClient,
  }) : repository = repository ?? MockGameRepository() {
    activeGame = ActiveGameState(
      countdown: GameCountdown.start(activeGameDuration),
    );
    _lastGameClockUpdate = DateTime.now();
    _initializeV1Demo();
  }
  final MockGameRepository repository;
  final Duration activeGameDuration;
  final BackendApiClient? backendClient;
  String? backendPlayerId;
  bool backendConnected = false;
  String? backendError;
  late ActiveGameState activeGame;
  late DateTime _lastGameClockUpdate;
  late ScoringService _scoringService;
  late Map<String, ParticipantScore> demoScores;
  late HintState hintState;
  late QuestionAttempt questionAttempt;
  late PerfectQuestionBonus _questionBonus;
  late OutsideZoneTracker outsideZoneTracker;
  late GamePowerInventory powerInventory;
  int personallyFound = 2;
  int questionPoints = 0;
  int findSequence = 0;
  bool inActiveZone = true;
  DateTime? zoneReturnDeadline;
  double activeZoneRadiusMeters = 5000;
  bool gameFinished = false;
  bool playerActive = true;
  int currentAttemptPoints = 0;
  int gamesPlayed = 5;
  int wins = 3;
  int points = 840;
  String displayName = 'Arie';
  String profileCity = '';
  String profileAge = '';
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

  bool join(String id, [DateTime? timestamp]) {
    Game? game;
    for (final candidate in repository.availableGames) {
      if (candidate.id == id) {
        game = candidate;
        break;
      }
    }
    if (game == null) return false;
    if (game.scheduledStart != null) {
      final lifecycle = GameLifecycle(
        startsAt: game.scheduledStart!,
        duration: game.duration,
      );
      if (!lifecycle.canJoin(timestamp ?? DateTime.now())) return false;
    }
    repository.join(id);
    notifyListeners();
    return true;
  }

  void publish(Game game) {
    repository.publish(game);
    notifyListeners();
  }

  void playerWasFound() {
    if (!playerActive || gameFinished) return;
    playerActive = false;
    notifyListeners();
  }

  bool rejoinAfterFound({required bool allowed}) {
    if (!allowed || playerActive || gameFinished) return false;
    playerActive = true;
    currentAttemptPoints = 0;
    questionPoints = 0;
    demoScores['me'] = ParticipantScore(
      id: 'me',
      role: demoScores['me']!.role,
      value: 0,
    );
    notifyListeners();
    return true;
  }

  bool foundPlayer() {
    final hider = demoScores['hider-1'];
    if (hider == null || !hider.active) return false;
    final outcome = _scoringService.registerFind(
      FindEvent(
        id: 'demo-find-${findSequence++}',
        finderId: 'me',
        hiderId: 'hider-1',
      ),
      demoScores,
    );
    if (!outcome.applied) return false;
    activeGame = activeGame.playerFound();
    personallyFound++;
    notifyListeners();
    return true;
  }

  HintDecision useHint([DateTime? timestamp]) {
    final elapsed = activeGame.elapsed.inMicroseconds;
    final total = activeGame.countdown.total.inMicroseconds;
    final quarter =
        total == 0 ? 4 : (elapsed * 4 ~/ total).clamp(0, 3).toInt() + 1;
    final decision = const HintService().use(
      state: hintState,
      now: timestamp ?? DateTime.now(),
      quarter: quarter,
      zoneAllowsHints:
          ZoneRules.allowsHintsAndQuestions(activeZoneRadiusMeters),
    );
    if (decision.allowed) notifyListeners();
    return decision;
  }

  bool startQuestionRound() {
    final started = questionAttempt.start(
      isPrivateGame: true,
      questionsEnabled:
          ZoneRules.allowsHintsAndQuestions(activeZoneRadiusMeters),
      inRange: true,
    );
    if (started) notifyListeners();
    return started;
  }

  void updateQuestionRange(bool inRange, [DateTime? timestamp]) {
    questionAttempt.updateRange(
      inRange: inRange,
      now: timestamp ?? DateTime.now(),
    );
    notifyListeners();
  }

  int completeQuestionRound(int correct) {
    final earned = questionAttempt.complete(correct);
    final bonus = _questionBonus.award('me', [questionAttempt], 1);
    questionPoints += earned + bonus;
    currentAttemptPoints += earned + bonus;
    points += earned + bonus;
    notifyListeners();
    return earned + bonus;
  }

  bool registerZoneMeasurement({
    required bool inside,
    bool reliable = true,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    final outside = outsideZoneTracker.update(
      inside: inside,
      reliable: reliable,
      now: now,
    );
    inActiveZone = !outside;
    zoneReturnDeadline = outside
        ? outsideZoneTracker.confirmedOutsideAt!.add(
            ZoneRules.returnTime(
              distanceMeters: 120,
              speedMetersPerSecond: 1.4,
              gameDuration: activeGameDuration,
            ),
          )
        : null;
    notifyListeners();
    return outside;
  }

  void tickActiveGame([Duration amount = const Duration(seconds: 1)]) {
    final next = activeGame.tick(amount);
    if (identical(next, activeGame)) return;
    activeGame = next;
    if (next.status == GameStatus.completed && !gameFinished) {
      gameFinished = true;
      powerInventory = powerInventory.finishGame();
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

  double playerValue(PlayerRole role) {
    final base = DemoPlayerValueRules.calculate(
      role: role,
      elapsed: activeGame.elapsed,
      playersFound: activeGame.playersFound,
      total: activeGame.countdown.total,
    );
    return role == PlayerRole.seeker ? base + demoScores['me']!.value : base;
  }

  double get findDistanceMeters =>
      ZoneRules.findDistance(activeZoneRadiusMeters);

  bool activateStobbePower(StobbePowerKind kind) {
    final updated = powerInventory.use(kind, DateTime.now());
    if (identical(updated, powerInventory)) return false;
    powerInventory = updated;
    notifyListeners();
    return true;
  }

  bool get backendAvailable => backendClient != null && backendConnected;

  Future<void> refreshBackendGames() async {
    final client = backendClient;
    if (client == null || !backendConnected) return;
    try {
      final games = await client.fetchAvailableGames();
      repository.replaceAvailableGames(games);
      backendError = null;
      notifyListeners();
    } on BackendApiException catch (error) {
      backendError = error.code;
      notifyListeners();
    }
  }

  Future<bool> publishAsync(Game game) async {
    final client = backendClient;
    if (client == null) {
      publish(game);
      return false;
    }
    if (!backendConnected) {
      final connected = await connectBackend();
      if (!connected) {
        publish(game);
        return false;
      }
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await client.createGame(game);
        await refreshBackendGames();
        return true;
      } on BackendApiException catch (error) {
        if (error.statusCode == 401 && attempt == 0) {
          final reconnected = await connectBackend();
          if (reconnected) continue;
        }
        backendError = error.code;
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  Future<bool> joinAsync(String id, [DateTime? timestamp]) async {
    final client = backendClient;
    if (client == null) return join(id, timestamp);
    if (!backendConnected) {
      final connected = await connectBackend();
      if (!connected) return join(id, timestamp);
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await client.joinGame(id);
        final joined = join(id, timestamp);
        await refreshBackendGames();
        return joined;
      } on BackendApiException catch (error) {
        if (error.statusCode == 401 && attempt == 0) {
          final reconnected = await connectBackend();
          if (reconnected) continue;
        }
        backendError = error.code;
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  Future<bool> restoreBackendSession() async {
    final client = backendClient;
    if (client == null) return false;
    final session = await client.restorePlayerSession();
    if (session == null) return false;
    backendPlayerId = session.playerId;
    displayName = session.profileName;
    backendConnected = true;
    backendError = null;
    await refreshBackendGames();
    notifyListeners();
    return true;
  }

  Future<bool> connectBackend() async {
    final client = backendClient;
    if (client == null) {
      backendConnected = false;
      backendError = 'backend_not_configured';
      notifyListeners();
      return false;
    }
    try {
      final session = await client.registerPlayer(displayName);
      backendPlayerId = session.playerId;
      backendConnected = true;
      backendError = null;
      await refreshBackendGames();
      notifyListeners();
      return true;
    } on BackendApiException catch (error) {
      backendConnected = false;
      backendError = error.code;
      notifyListeners();
      return false;
    } catch (_) {
      backendConnected = false;
      backendError = 'connection_failed';
      notifyListeners();
      return false;
    }
  }

  String? setDisplayName(String value) {
    final trimmed = value.trim();
    final error = ProfileNameValidation.validate(trimmed);
    if (error != null) return error;
    displayName = trimmed;
    notifyListeners();
    return null;
  }

  void setProfileCity(String value) {
    profileCity = value.trim();
    notifyListeners();
  }

  void setProfileAge(String value) {
    profileAge = value.trim();
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
    powerInventory = powerInventory.finishGame();
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
    _initializeV1Demo();
    gameFinished = false;
    playerActive = true;
    currentAttemptPoints = 0;
    gamesPlayed = 5;
    wins = 3;
    points = 840;
    displayName = 'Arie';
    profileCity = '';
    profileAge = '';
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

  void _initializeV1Demo() {
    _scoringService = ScoringService();
    demoScores = {
      'me': ParticipantScore(id: 'me', role: ScoreRole.seeker, value: 0),
      'seeker-2': ParticipantScore(
        id: 'seeker-2',
        role: ScoreRole.seeker,
        value: 0,
      ),
      'hider-1': ParticipantScore(
        id: 'hider-1',
        role: ScoreRole.hider,
        value: 100,
      ),
      'hider-2': ParticipantScore(
        id: 'hider-2',
        role: ScoreRole.hider,
        value: 100,
      ),
    };
    hintState = HintState(points: 50);
    questionAttempt = QuestionAttempt(playerId: 'me', subjectId: 'mila');
    _questionBonus = PerfectQuestionBonus();
    outsideZoneTracker = OutsideZoneTracker();
    personallyFound = 2;
    questionPoints = 0;
    currentAttemptPoints = 0;
    playerActive = true;
    findSequence = 0;
    inActiveZone = true;
    zoneReturnDeadline = null;
    activeZoneRadiusMeters = 5000;
    const drone = StobbePowerDefinition(
      kind: StobbePowerKind.digitalDrone,
      name: 'Digitale drone',
      maxUsesPerGame: 1,
      maxInventory: 1,
      duration: Duration(minutes: 2),
      cooldown: Duration(minutes: 2),
    );
    const arm = StobbePowerDefinition(
      kind: StobbePowerKind.stobbeArm,
      name: 'Arm van de Stobbe',
      maxUsesPerGame: 3,
      maxInventory: 3,
      duration: Duration(minutes: 3),
      cooldown: Duration(minutes: 3),
    );
    const invisible = StobbePowerDefinition(
      kind: StobbePowerKind.invisibilityPotion,
      name: 'Onzichtbaar',
      maxUsesPerGame: 1,
      maxInventory: 1,
      duration: Duration(minutes: 2),
      cooldown: Duration(minutes: 2),
    );
    powerInventory = const GamePowerInventory()
        .add(drone)
        .add(arm)
        .add(arm)
        .add(invisible)
        .startActivePhase();
  }
}
