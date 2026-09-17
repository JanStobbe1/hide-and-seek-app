enum ThemePreference { forest, ocean, sunset, violet }

enum PlayerMarker { ghost, wolf, police, explorer }

class FriendProfile {
  const FriendProfile({
    required this.name,
    required this.city,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.points,
  });

  final String name;
  final String city;
  final int gamesPlayed;
  final int gamesWon;
  final int points;
}
