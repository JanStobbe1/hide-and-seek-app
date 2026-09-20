import 'models.dart';

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
    if (!seekersWon(found: totalFound, total: totalHiders))
      return personallyFound / totalFound < .1
          ? ResultTone.veryNegative
          : ResultTone.negative;
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
    if (!found)
      return survivors == 1 ? ResultTone.mostPositive : ResultTone.veryPositive;
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
  });
  final String name, rank;
  final int? age, gamesWon, gamesPlayed, streak;
  final String? photo;
  final List<String> badges;
}

class PrivacyService {
  const PrivacyService();
  Map<String, Object?> payload(
    ParticipantView p, {
    required bool friend,
    required bool shareAge,
    required bool sharePhoto,
  }) =>
      {
        'name': p.name,
        'rank': p.rank,
        if (friend && shareAge) 'age': p.age,
        if (friend && sharePhoto) 'photo': p.photo,
        if (friend) 'gamesWon': p.gamesWon,
        if (friend) 'gamesPlayed': p.gamesPlayed,
        if (friend) 'badges': p.badges,
        if (friend) 'streak': p.streak,
      };
}
