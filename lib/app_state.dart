import 'package:flutter/foundation.dart';

import 'data/mock_game_repository.dart';
import 'domain/countdown.dart';
import 'domain/game_engine.dart';
import 'domain/game_lifecycle.dart';
import 'domain/friends.dart';
import 'domain/hints.dart';
import 'domain/models.dart';
import 'domain/player_value_rules.dart';
import 'domain/private_questions.dart';
import 'domain/profile_validation.dart';
import 'domain/profile_models.dart';
import 'domain/scoring.dart';
import 'domain/seeker_decay.dart';

class AppState extends ChangeNotifier {
  AppState({
    MockGameRepository? repository,
    this.activeGameDuration = const Duration(minutes: 30),
  }) : repository = repository ?? MockGameRepository() {
    activeGame = ActiveGameState(
      countdown: GameCountdown.start(activeGameDuration),
    );
    _lastGameClockUpdate = DateTime.now();
    _resetFindingState();
    _resetHintState();
  }
  final MockGameRepository repository;
  final Duration activeGameDuration;
  late ActiveGameState activeGame;
  late DateTime _lastGameClockUpdate;
  bool gameFinished = false;
  final ResultPresentationTracker resultPresentation =
      ResultPresentationTracker();
  final FriendshipService friendshipService = FriendshipService();
  late FindingState findingState;
  late HintState hintState;
  int _findingEventSequence = 0;
  final Map<String, QuestionAttempt> questionAttempts = {};
  final Map<String, int> questionResults = {};
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

  String? joinBlockReason(String id, {DateTime? now}) {
    final game = repository.availableGames
        .where((candidate) => candidate.id == id)
        .firstOrNull;
    if (game == null) return 'Dit spel is niet meer beschikbaar.';
    if (repository.joinedGames.any((candidate) => candidate.id == id)) {
      return 'Je doet al mee aan dit spel.';
    }
    if (game.participants >= game.maxParticipants) {
      return 'Dit spel heeft het maximum aantal deelnemers bereikt.';
    }
    final start = game.scheduledStart;
    if (start != null &&
        !const GameLifecycle().canJoin(
          startedAt: start,
          now: now ?? DateTime.now(),
        )) {
      return 'De instapperiode is voorbij. Je kunt tot 5 minuten na de start meedoen.';
    }
    return null;
  }

  bool join(String id, {DateTime? now}) {
    if (joinBlockReason(id, now: now) != null) return false;
    repository.join(id);
    final joined = repository.joinedGames.any(
      (candidate) => candidate.id == id,
    );
    if (joined) notifyListeners();
    return joined;
  }

  void publish(Game game) {
    repository.publish(game);
    notifyListeners();
  }

  bool foundPlayer() {
    final hider = findingState.players.values
        .where((player) => player.role == PlayerRole.hider && player.active)
        .firstOrNull;
    if (hider == null || activeGame.status != GameStatus.active) return false;
    final registered = const FindingService().register(
      state: findingState,
      eventId: 'find-${_findingEventSequence++}',
      finderId: 'me',
      hiderId: hider.id,
    );
    if (!registered) return false;
    activeGame = activeGame.playerFound();
    points = findingState.players['me']!.points;
    hintState.points = points;
    _evaluateGameEnd();
    notifyListeners();
    return true;
  }

  int get activeHiders => findingState.players.values
      .where((player) => player.role == PlayerRole.hider && player.active)
      .length;

  int get activeSeekers => findingState.players.values
      .where((player) => player.role == PlayerRole.seeker && player.active)
      .length;

  HintUseResult useHint({DateTime? now, bool zoneLargeEnough = true}) {
    final elapsed = activeGame.elapsed;
    final totalMicros = activeGameDuration.inMicroseconds;
    final quarter = totalMicros == 0
        ? 3
        : ((elapsed.inMicroseconds * 4) ~/ totalMicros).clamp(0, 3);
    final result = const HintService().use(
      state: hintState,
      now: now ?? DateTime.now(),
      quarter: quarter,
      zoneLargeEnough: zoneLargeEnough,
    );
    if (result.started) {
      points = result.points;
      notifyListeners();
    }
    return result;
  }

  int get finalPointsAfterHints => const HintService().finalPoints(hintState);

  QuestionAttempt questionAttemptFor(String subjectId) =>
      questionAttempts.putIfAbsent(
        subjectId,
        () => QuestionAttempt(playerId: 'me', subjectId: subjectId),
      );

  QuestionMarkerStatus questionVisibility({
    required String subjectId,
    required bool privateGame,
    required bool enabled,
    required bool inRange,
  }) =>
      const PrivateQuestionService().visibility(
        privateGame: privateGame,
        enabled: enabled,
        inRange: inRange,
        playerId: 'me',
        subjectId: subjectId,
        attempt: questionAttempts[subjectId],
      );

  void startQuestion(String subjectId) {
    final attempt = questionAttemptFor(subjectId);
    const PrivateQuestionService().start(attempt);
    notifyListeners();
  }

  int completeQuestion(String subjectId, int correct) {
    final attempt = questionAttemptFor(subjectId);
    final awarded = const PrivateQuestionService().complete(attempt, correct);
    if (attempt.status == QuestionMarkerStatus.completed) {
      questionResults[subjectId] = correct;
      points += awarded;
      hintState.points = points;
      notifyListeners();
    }
    return awarded;
  }

  void updateQuestionRange(
    String subjectId, {
    required bool inRange,
    DateTime? now,
  }) {
    final attempt = questionAttemptFor(subjectId);
    const PrivateQuestionService().updateRange(
      attempt,
      inRange: inRange,
      now: now ?? DateTime.now(),
    );
    notifyListeners();
  }

  void _resetHintState() {
    hintState = HintState(points: points);
  }

  void _resetFindingState() {
    findingState = FindingState([
      ScoringPlayer(id: 'me', role: PlayerRole.seeker, points: points),
      const ScoringPlayer(id: 'seeker-2', role: PlayerRole.seeker, points: 0),
      for (var i = 0; i < 15; i++)
        ScoringPlayer(
          id: 'hider-$i',
          role: PlayerRole.hider,
          points: 50 + i * 2,
        ),
    ]);
    _findingEventSequence = 0;
    questionAttempts.clear();
    questionResults.clear();
  }

  void useInvisibility() {
    activeGame = activeGame.useInvisibility();
    notifyListeners();
  }

  void tickActiveGame([Duration amount = const Duration(seconds: 1)]) {
    final next = activeGame.tick(amount);
    if (identical(next, activeGame)) return;
    activeGame = next;
    _evaluateGameEnd();
    notifyListeners();
  }

  void _evaluateGameEnd() {
    final status = const GameLifecycle().statusFor(
      remaining: activeGame.countdown.remaining,
      activeHiders: activeHiders,
      activeSeekers: activeSeekers,
    );
    if (status == GameStatus.completed && !gameFinished) {
      activeGame = activeGame.finish();
      gameFinished = true;
      gamesPlayed++;
    }
  }

  bool shouldAutoShowResult() =>
      gameFinished && resultPresentation.shouldAutoShow('active-demo');

  bool canOpenResultManually() =>
      resultPresentation.canOpenManually('active-demo');

  void syncActiveGameClock([DateTime? timestamp]) {
    final now = timestamp ?? DateTime.now();
    if (now.isBefore(_lastGameClockUpdate)) return;
    final elapsed = now.difference(_lastGameClockUpdate);
    _lastGameClockUpdate = now;
    tickActiveGame(elapsed);
  }

  double playerValue(PlayerRole role) {
    if (role == PlayerRole.seeker) {
      final startValue = findingState.players['me']?.points.toDouble() ?? 0;
      return const SeekerDecay().valueAt(
        startValue: startValue,
        gameDuration: activeGameDuration,
        elapsed: activeGame.elapsed,
      );
    }
    return DemoPlayerValueRules.calculate(
      role: role,
      elapsed: activeGame.elapsed,
      playersFound: activeGame.playersFound,
    );
  }

  NameValidationResult setDisplayName(String value) {
    final validation = const ProfileNameValidator().validate(value);
    if (!validation.valid) return validation;
    displayName = value.trim();
    notifyListeners();
    return validation;
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

  FriendDecision requestFriend(String playerId, {DateTime? now}) {
    final decision = friendshipService.choose(
      from: 'me',
      to: playerId,
      now: now ?? DateTime.now(),
    );
    notifyListeners();
    return decision;
  }

  FriendDecision respondToFriendRequest(
    FriendRequest request, {
    required bool accept,
    DateTime? now,
  }) {
    final decision = accept
        ? friendshipService.accept(request, now ?? DateTime.now())
        : friendshipService.reject(request);
    notifyListeners();
    return decision;
  }

  FriendDecision blockFriendRequest(FriendRequest request) {
    final decision = friendshipService.block(request);
    notifyListeners();
    return decision;
  }

  bool canWithdrawFriendRequest(FriendRequest request) =>
      friendshipService.canWithdraw(request);

  void inviteFriend(String playerId) {
    friendshipService.invite(inviter: 'me', invitee: playerId);
    notifyListeners();
  }

  List<FriendRequest> get incomingFriendRequests =>
      friendshipService.requests.values
          .where(
            (request) =>
                request.receiver == 'me' &&
                request.decision == FriendDecision.pending,
          )
          .toList(growable: false);

  List<FriendRequest> get outgoingFriendRequests =>
      friendshipService.requests.values
          .where(
            (request) =>
                request.sender == 'me' &&
                request.decision == FriendDecision.pending,
          )
          .toList(growable: false);

  void seedIncomingFriendRequest({
    String playerId = 'player-mila',
    DateTime? createdAt,
  }) {
    friendshipService.requests.putIfAbsent(
      '$playerId->me',
      () => FriendRequest(
        sender: playerId,
        receiver: 'me',
        createdAt: createdAt ?? DateTime.now(),
      ),
    );
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
    _resetFindingState();
    _resetHintState();
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
