import '../config/game_config.dart';

enum QuestionMarkerStatus { own, unavailable, available, active, completed, failed }
class QuestionAttempt { QuestionAttempt({required this.playerId, required this.subjectId}); final String playerId; final String subjectId; QuestionMarkerStatus status = QuestionMarkerStatus.available; DateTime? leftRangeAt; int answered = 0; }
class PrivateQuestionService {
  const PrivateQuestionService({this.config = const GameConfig()}); final GameConfig config;
  static const scores = [0, 10, 20, 40, 60, 100];
  finalKey(String playerId, String subjectId) => '$playerId::$subjectId';
  QuestionMarkerStatus visibility({required bool privateGame, required bool enabled, required bool inRange, required String playerId, required String subjectId, QuestionAttempt? attempt}) {
    if (playerId == subjectId) return QuestionMarkerStatus.own;
    if (!privateGame || !enabled || !inRange) return QuestionMarkerStatus.unavailable;
    return attempt?.status ?? QuestionMarkerStatus.available;
  }
  void start(QuestionAttempt attempt) { if (attempt.status == QuestionMarkerStatus.available) attempt.status = QuestionMarkerStatus.active; }
  void updateRange(QuestionAttempt attempt, {required bool inRange, required DateTime now}) {
    if (attempt.status != QuestionMarkerStatus.active) return;
    if (inRange) { attempt.leftRangeAt = null; return; }
    attempt.leftRangeAt ??= now;
    if (now.difference(attempt.leftRangeAt!) > config.questionReturnGrace) attempt.status = QuestionMarkerStatus.failed;
  }
  int complete(QuestionAttempt attempt, int correct) { if (correct < 0 || correct > 5) throw RangeError.range(correct, 0, 5); if (attempt.status != QuestionMarkerStatus.active) return 0; attempt.status = QuestionMarkerStatus.completed; attempt.answered = 5; return scores[correct]; }
}
class PerfectQuestionBonus {
  final Set<String> _awarded = {};
  int award({required String playerId, required Set<String> expectedSubjects, required Map<String, int> results}) {
    if (_awarded.contains(playerId) || results.keys.toSet().difference(expectedSubjects).isNotEmpty || results.length != expectedSubjects.length || results.values.any((v) => v != 5)) return 0;
    _awarded.add(playerId); return 500;
  }
}
