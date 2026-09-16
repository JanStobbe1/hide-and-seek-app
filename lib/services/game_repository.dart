import '../domain/models.dart';

abstract interface class GameRepository {
  List<Game> get availableGames;
  List<Game> get joinedGames;
  void join(String id);
  void publish(Game game);
  void reset();
}
