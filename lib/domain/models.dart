enum PlayerRole { seeker, hider }

enum GameStatus { available, waiting, active, completed, abandoned }

enum StartCondition { participantCount, scheduled }

class Player {
  const Player({required this.name, required this.alias, required this.age, required this.city, required this.rank});
  final String name;
  final String alias;
  final int age;
  final String city;
  final String rank;
}

class SearchArea {
  const SearchArea({required this.country, required this.province, required this.city, required this.neighbourhood, required this.specificArea});
  final String country;
  final String province;
  final String city;
  final String neighbourhood;
  final String specificArea;

  String get label => '$city, $province';
}

class GameRules {
  const GameRules({this.hintsEnabled = true, this.questionsEnabled = true, this.hidersCanWin = true, this.topSeekerCanWin = true, this.playersPerSeeker = 6});
  final bool hintsEnabled;
  final bool questionsEnabled;
  final bool hidersCanWin;
  final bool topSeekerCanWin;
  final int playersPerSeeker;
}

class Game {
  const Game({required this.id, required this.name, required this.organizer, required this.description, required this.area, required this.status, required this.start, required this.duration, required this.entryFee, required this.participants, required this.maxParticipants, required this.distanceKm, this.isPublic = true, this.rules = const GameRules()});
  final String id;
  final String name;
  final String organizer;
  final String description;
  final SearchArea area;
  final GameStatus status;
  final DateTime start;
  final Duration duration;
  final double entryFee;
  final int participants;
  final int maxParticipants;
  final double distanceKm;
  final bool isPublic;
  final GameRules rules;

  Game copyWith({GameStatus? status, int? participants}) => Game(id: id, name: name, organizer: organizer, description: description, area: area, status: status ?? this.status, start: start, duration: duration, entryFee: entryFee, participants: participants ?? this.participants, maxParticipants: maxParticipants, distanceKm: distanceKm, isPublic: isPublic, rules: rules);
}

class GameParticipant {
  const GameParticipant({required this.player, required this.role, this.found = false});
  final Player player;
  final PlayerRole role;
  final bool found;
}

class GameResult {
  const GameResult({required this.role, required this.points, this.playersFound = 0, this.survivalTime, this.mockReward = 0});
  final PlayerRole role;
  final int points;
  final int playersFound;
  final Duration? survivalTime;
  final double mockReward;
}

class FinancialSummary {
  const FinancialSummary({required this.grossPool, required this.platformFee, required this.prizePool});
  final double grossPool;
  final double platformFee;
  final double prizePool;
}
