import '../config/app_config.dart';

enum QuestionMarkerStatus { own, available, inProgress, completed, failed }

class QuestionAttempt {
  QuestionAttempt({required this.playerId, required this.subjectId})
      : status = playerId == subjectId ? QuestionMarkerStatus.own : QuestionMarkerStatus.available;
  final String playerId;
  final String subjectId;
  QuestionMarkerStatus status;
  DateTime? leftRangeAt;
  int? correctAnswers;

  bool get visible => status != QuestionMarkerStatus.own && status != QuestionMarkerStatus.failed;

  bool start({required bool isPrivateGame, required bool questionsEnabled, required bool inRange}) {
    if (!isPrivateGame || !questionsEnabled || !inRange || status != QuestionMarkerStatus.available) return false;
    status = QuestionMarkerStatus.inProgress;
    return true;
  }

  void updateRange({required bool inRange, required DateTime now}) {
    if (status != QuestionMarkerStatus.inProgress) return;
    if (inRange) {
      leftRangeAt = null;
      return;
    }
    leftRangeAt ??= now;
    if (now.difference(leftRangeAt!) > AppConfig.questionReturnGrace) {
      status = QuestionMarkerStatus.failed;
    }
  }

  int complete(int correct) {
    if (status != QuestionMarkerStatus.inProgress || correct < 0 || correct > 5) return 0;
    correctAnswers = correct;
    status = QuestionMarkerStatus.completed;
    return QuestionScoring.pointsFor(correct);
  }
}

abstract final class QuestionScoring {
  static const _points = [0, 10, 20, 40, 60, 100];
  static int pointsFor(int correct) {
    if (correct < 0 || correct > 5) throw RangeError.range(correct, 0, 5);
    return _points[correct];
  }
}

class PerfectQuestionBonus {
  final Set<String> _awardedPlayers = {};

  int award(String playerId, Iterable<QuestionAttempt> attempts, int otherParticipantCount) {
    if (_awardedPlayers.contains(playerId)) return 0;
    final relevant = attempts.where((attempt) => attempt.playerId == playerId && attempt.subjectId != playerId).toList();
    if (relevant.length != otherParticipantCount || relevant.any((attempt) => attempt.correctAnswers != 5)) return 0;
    _awardedPlayers.add(playerId);
    return 500;
  }
}
