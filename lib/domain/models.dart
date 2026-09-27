enum PlayerRole { seeker, hider }

enum GameStatus { available, waiting, active, completed, abandoned }

enum StartCondition { participantCount, scheduled }

enum GameType {
  classic,
  everyoneHunts,
}

extension GameTypePresentation on GameType {
  String get label => switch (this) {
        GameType.classic => 'Klassiek',
        GameType.everyoneHunts => 'Iedereen jaagt',
      };

  String get description => switch (this) {
        GameType.classic => 'Vaste zoekers en verstoppers tot het einde.',
        GameType.everyoneHunts =>
          'Iedere speler is tegelijk zoeker én verstopper.',
      };
}

class Player {
  const Player({
    required this.name,
    required this.alias,
    required this.age,
    required this.city,
    required this.rank,
  });

  final String name;
  final String alias;
  final int age;
  final String city;
  final String rank;
}

class SearchArea {
  const SearchArea({
    required this.country,
    required this.province,
    required this.city,
    required this.neighbourhood,
    required this.specificArea,
  });

  final String country;
  final String province;
  final String city;
  final String neighbourhood;
  final String specificArea;

  String get label => '$city, $province';
}

class GameRules {
  const GameRules({
    this.hintsEnabled = true,
    this.questionsEnabled = true,
    this.hidersCanWin = true,
    this.topSeekerCanWin = true,
    this.playersPerSeeker = 6,
    this.seekersCount = 1,
    this.hidersCount = 0,
    this.roleSwitchEnabled = false,
    this.stobbePowersEnabled = false,
    this.gameType = GameType.classic,
    this.allowRejoinAfterFound = false,
  });

  final bool hintsEnabled;
  final bool questionsEnabled;
  final bool hidersCanWin;
  final bool topSeekerCanWin;
  final int playersPerSeeker;
  final int seekersCount;
  final int hidersCount;
  final bool roleSwitchEnabled;
  final bool stobbePowersEnabled;
  final GameType gameType;
  final bool allowRejoinAfterFound;
}

class Game {
  const Game({
    required this.id,
    required this.name,
    required this.organizer,
    this.createdBy,
    required this.description,
    required this.area,
    required this.status,
    required this.duration,
    required this.participants,
    required this.maxParticipants,
    required this.distanceKm,
    required this.startCondition,
    this.scheduledStart,
    this.participantThreshold,
    this.isPublic = true,
    this.rules = const GameRules(),
  })  : assert(
          startCondition != StartCondition.scheduled || scheduledStart != null,
          'A scheduled game requires a start date.',
        ),
        assert(
          startCondition != StartCondition.participantCount ||
              (participantThreshold != null && participantThreshold > 0),
          'A participant-start game requires a positive threshold.',
        );

  final String id;
  final String name;
  final String organizer;
  final String? createdBy;
  final String description;
  final SearchArea area;
  final GameStatus status;
  final Duration duration;
  final int participants;
  final int maxParticipants;
  final double distanceKm;
  final StartCondition startCondition;
  final DateTime? scheduledStart;
  final int? participantThreshold;
  final bool isPublic;
  final GameRules rules;

  DateTime? get scheduledEnd => scheduledStart?.add(duration);

  Game copyWith({GameStatus? status, int? participants}) => Game(
        id: id,
        name: name,
        organizer: organizer,
        createdBy: createdBy,
        description: description,
        area: area,
        status: status ?? this.status,
        duration: duration,
        participants: participants ?? this.participants,
        maxParticipants: maxParticipants,
        distanceKm: distanceKm,
        startCondition: startCondition,
        scheduledStart: scheduledStart,
        participantThreshold: participantThreshold,
        isPublic: isPublic,
        rules: rules,
      );
}

class GameParticipant {
  const GameParticipant({
    required this.player,
    required this.role,
    this.found = false,
  });

  final Player player;
  final PlayerRole role;
  final bool found;
}

class GameResult {
  const GameResult({
    required this.role,
    required this.points,
    this.playersFound = 0,
    this.survivalTime,
  });

  final PlayerRole role;
  final int points;
  final int playersFound;
  final Duration? survivalTime;
}
