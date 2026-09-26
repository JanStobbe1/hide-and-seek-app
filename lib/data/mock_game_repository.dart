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
  MockGameRepository() {
    reset();
  }

  late List<Game> _available;
  final List<Game> _joined = [];

  @override
  List<Game> get availableGames => List.unmodifiable(_available);

  @override
  List<Game> get joinedGames => List.unmodifiable(_joined);

  void replaceAvailableGames(List<Game> games) {
    _available = List<Game>.from(games);
  }

  @override
  void reset() {
    _joined.clear();
    final start = DateTime(2026, 10, 25, 16);
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
      status: GameStatus.waiting,
    );
    _available[index] = game;
    _joined.add(game);
  }

  @override
  void publish(Game game) => _available.add(game);
}
