enum ResultTone {
  mostNegative,
  veryNegative,
  negative,
  neutral,
  positive,
  veryPositive,
  mostPositive,
}

class ResultService {
  const ResultService();
  bool seekersWon({required int found, required int total}) =>
      total > 0 && found / total >= .5;
  ResultTone seekerTone({
    required int personallyFound,
    required int totalFound,
    required int totalHiders,
  }) {
    if (totalFound == 0) return ResultTone.mostNegative;
    if (!seekersWon(found: totalFound, total: totalHiders)) {
      return personallyFound / totalFound < .1
          ? ResultTone.veryNegative
          : ResultTone.negative;
    }
    final share = personallyFound / totalFound;
    if (share >= 1) return ResultTone.mostPositive;
    if (share >= .5) return ResultTone.veryPositive;
    if (share <= .1) return ResultTone.neutral;
    return ResultTone.positive;
  }

  ResultTone hiderTone({
    required bool found,
    required Duration? foundAt,
    required Duration total,
    required int survivors,
  }) {
    if (!found) {
      return survivors == 1 ? ResultTone.mostPositive : ResultTone.veryPositive;
    }
    final ratio = foundAt!.inMicroseconds / total.inMicroseconds;
    if (ratio >= .75) return ResultTone.positive;
    if (ratio < .25) return ResultTone.mostNegative;
    if (ratio < .5) return ResultTone.negative;
    return ResultTone.neutral;
  }
}

class ParticipantView {
  const ParticipantView({
    required this.name,
    required this.rank,
    this.age,
    this.photo,
    this.gamesWon,
    this.gamesPlayed,
    this.badges = const [],
    this.streak,
    this.upcomingGames = const [],
    this.currentGame,
    this.points,
    this.pointsToNextRank,
  });

  final String name;
  final String rank;
  final int? age;
  final String? photo;
  final int? gamesWon;
  final int? gamesPlayed;
  final List<String> badges;
  final int? streak;
  final List<String> upcomingGames;

  // These fields exist in the source model so the privacy projection can
  // explicitly prove they never reach friend/non-friend UI payloads.
  final String? currentGame;
  final int? points;
  final int? pointsToNextRank;
}

class PrivacyService {
  const PrivacyService();

  Map<String, Object> payload(
    ParticipantView participant, {
    required bool friend,
    required bool shareAge,
    required bool sharePhoto,
  }) {
    final result = <String, Object>{
      'name': participant.name,
      'rank': participant.rank,
    };
    if (!friend) return result;

    if (shareAge && participant.age != null) {
      result['age'] = participant.age!;
    }
    if (sharePhoto && participant.photo != null) {
      result['photo'] = participant.photo!;
    }
    if (participant.gamesWon != null) {
      result['gamesWon'] = participant.gamesWon!;
    }
    if (participant.gamesPlayed != null) {
      result['gamesPlayed'] = participant.gamesPlayed!;
    }
    if (participant.badges.isNotEmpty) {
      result['badges'] = List<String>.unmodifiable(participant.badges);
    }
    if (participant.streak != null) {
      result['streak'] = participant.streak!;
    }
    if (participant.upcomingGames.isNotEmpty) {
      result['upcomingGames'] =
          List<String>.unmodifiable(participant.upcomingGames);
    }

    // Deliberately omitted: currentGame, points and pointsToNextRank.
    return result;
  }
}
