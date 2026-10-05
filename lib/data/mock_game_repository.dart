import '../domain/game_setup.dart';
import '../domain/models.dart';
import '../services/game_repository.dart';

const demoArea = SearchArea(
  country: 'Nederland',
  province: 'Flevoland',
  city: 'Almere',
  neighbourhood: 'Alle',
  specificArea: 'Niet van toepassing',
);

class MockGameRepository implements GameRepository {
  MockGameRepository({this.includeDemoOngoingGames = false}) {
    reset();
  }

  final bool includeDemoOngoingGames;
  late List<Game> _available;
  final List<Game> _joined = [];

  @override
  List<Game> get availableGames => List.unmodifiable(_available);

  @override
  List<Game> get joinedGames => List.unmodifiable(_joined);

  void replaceAvailableGames(List<Game> games) {
    _available = List<Game>.from(games);
  }

  void replaceJoinedGames(List<Game> games) {
    _joined
      ..clear()
      ..addAll(games);
  }

  @override
  void reset() {
    _joined.clear();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day + 20, 16);
    _available = [
      Game(
        id: 'epic',
        name: 'MostEpicGameEver',
        organizer: 'Jan',
        description:
            'Een avontuurlijk verstopspel in de bossen van de Utrechtse Heuvelrug.',
        area: const SearchArea(
          country: 'Nederland',
          province: 'Utrecht',
          city: 'Utrechtse Heuvelrug',
          neighbourhood: 'Bosgebied',
          specificArea: 'Start bij de uitkijktoren',
        ),
        status: GameStatus.available,
        duration: const Duration(hours: 3),
        participants: 20,
        maxParticipants: 30,
        distanceKm: 34,
        startCondition: StartCondition.scheduled,
        scheduledStart: start,
      ),
      _game('wats', 'Watskeburt', 2.4, 12, start.add(const Duration(days: 2))),
      _game(
        'verst',
        'Verstoppertje',
        5.8,
        8,
        start.add(const Duration(days: 1)),
      ),
      _game(
        'gadget',
        'Inspector Gadget',
        12,
        16,
        start.add(const Duration(hours: 5)),
      ),
      _game('test', 'Test123', 1.2, 4, start.add(const Duration(days: 4))),
    ];
    if (includeDemoOngoingGames) {
      final ongoingGames = _ongoingDemoGames(now);
      _available.addAll(ongoingGames);
      _joined.addAll(ongoingGames);
    }
  }

  static Game _game(
    String id,
    String name,
    double distance,
    int participants,
    DateTime start,
  ) =>
      Game(
        id: id,
        name: name,
        organizer: 'Demo-organisator',
        description:
            'Vind de beste verstopplek en blijf uit handen van de zoekers.',
        area: demoArea,
        status: GameStatus.available,
        duration: const Duration(hours: 2),
        participants: participants,
        maxParticipants: 24,
        distanceKm: distance,
        startCondition: StartCondition.scheduled,
        scheduledStart: start,
      );

  @override
  void join(String id) {
    final index = _available.indexWhere((game) => game.id == id);
    if (index < 0 || _joined.any((game) => game.id == id)) return;
    final game = _available[index].copyWith(
      participants: _available[index].participants + 1,
      status: _available[index].status == GameStatus.active
          ? GameStatus.active
          : GameStatus.waiting,
    );
    _available[index] = game;
    _joined.add(game);
  }

  void removeJoined(String id) {
    _joined.removeWhere((game) => game.id == id);
  }

  void removeGame(String id) {
    _joined.removeWhere((game) => game.id == id);
    _available.removeWhere((game) => game.id == id);
  }

  @override
  void publish(Game game) {
    _available.removeWhere((item) => item.id == game.id);
    _available.add(game);
    if (_joined.every((item) => item.id != game.id)) {
      _joined.add(game);
    }
  }
}


const _demoActiveArea = SearchArea(
  country: 'Nederland',
  province: 'Flevoland',
  city: 'Almere',
  neighbourhood: 'Centrum',
  specificArea: 'Weerwater',
  boundary: [
    AreaPoint(52.3655, 5.2040),
    AreaPoint(52.3745, 5.2040),
    AreaPoint(52.3745, 5.2200),
    AreaPoint(52.3655, 5.2200),
  ],
);

List<Game> _ongoingDemoGames(DateTime now) => [
      _ongoingGame(
        id: 'demo-powers-classic',
        name: 'Stobbekrachten in het park',
        description:
            'Klassiek zoekspel. Testuser 1 doet mee en heeft Stobbekrachtfiches in de tas.',
        participants: 8,
        startsAt: now.subtract(const Duration(minutes: 12)),
        rules: const GameRules(
          stobbePowersEnabled: true,
          seekersCount: 2,
          hidersCount: 6,
        ),
      ),
      _ongoingGame(
        id: 'demo-no-powers',
        name: 'Zonder Stobbekrachten',
        description:
            'Klassiek zoekspel zonder Stobbekrachtfiches. Testuser 1 doet mee.',
        participants: 6,
        startsAt: now.subtract(const Duration(minutes: 24)),
        rules: const GameRules(
          stobbePowersEnabled: false,
          seekersCount: 1,
          hidersCount: 5,
        ),
      ),
      _ongoingGame(
        id: 'demo-everyone-hunts',
        name: 'Iedereen jaagt',
        description:
            'Iedere speler kan zoeken en door anderen gevonden worden. Testuser 1 doet mee.',
        participants: 7,
        startsAt: now.subtract(const Duration(minutes: 8)),
        rules: const GameRules(
          gameType: GameType.everyoneHunts,
          stobbePowersEnabled: true,
        ),
      ),
      _ongoingGame(
        id: 'demo-testuser-seeker',
        name: 'Zoeker Testuser 1',
        description:
            'Klassiek spel met twee zoekers. Testuser 1 is zoeker; Mila is verstopt en kan worden gevonden.',
        participants: 6,
        startsAt: now.subtract(const Duration(minutes: 18)),
        rules: const GameRules(
          stobbePowersEnabled: true,
          seekersCount: 2,
          hidersCount: 4,
        ),
      ),
    ];

Game _ongoingGame({
  required String id,
  required String name,
  required String description,
  required int participants,
  required DateTime startsAt,
  required GameRules rules,
}) =>
    Game(
      id: id,
      name: name,
      organizer: 'Mr. Stobbe',
      description: description,
      area: _demoActiveArea,
      status: GameStatus.active,
      duration: const Duration(hours: 2),
      participants: participants,
      maxParticipants: 12,
      distanceKm: 0.0,
      startCondition: StartCondition.scheduled,
      scheduledStart: startsAt,
      rules: rules,
    );
