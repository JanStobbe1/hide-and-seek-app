enum ThemePreference { forest, ocean, sunset, violet }

enum PlayerMarker { ghost, wolf, police, explorer }

class FriendProfile {
  const FriendProfile({
    required this.name,
    required this.rank,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.dailyStreak,
    this.badges = const [],
    this.upcomingGames = const [],
    this.age,
    this.photo,
  });

  final String name;
  final String rank;
  final int gamesPlayed;
  final int gamesWon;
  final int dailyStreak;
  final List<String> badges;
  final List<String> upcomingGames;
  final int? age;
  final String? photo;
}
