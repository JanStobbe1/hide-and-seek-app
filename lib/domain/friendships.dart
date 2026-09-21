enum FriendRequestStatus { pending, accepted, declined, blocked, expired }

class FriendRequest {
  FriendRequest(
      {required this.senderId,
      required this.receiverId,
      required this.createdAt});
  final String senderId;
  final String receiverId;
  final DateTime createdAt;
  FriendRequestStatus status = FriendRequestStatus.pending;

  bool accept(DateTime now) {
    if (status != FriendRequestStatus.pending) return false;
    if (now.isAfter(createdAt.add(const Duration(days: 2)))) {
      status = FriendRequestStatus.expired;
      return false;
    }
    status = FriendRequestStatus.accepted;
    return true;
  }

  void decline() {
    if (status == FriendRequestStatus.pending) {
      status = FriendRequestStatus.declined;
    }
  }

  void block() {
    if (status == FriendRequestStatus.pending) {
      status = FriendRequestStatus.blocked;
    }
  }
}

class FriendshipService {
  final Set<String> _choices = {};
  final Set<String> friendships = {};
  final List<FriendRequest> requests = [];
  String _pair(String a, String b) => ([a, b]..sort()).join(':');

  void choose(
      {required String from, required String to, required DateTime now}) {
    final directed = '$from>$to';
    if (!_choices.add(directed)) return;
    if (_choices.contains('$to>$from')) {
      friendships.add(_pair(from, to));
      requests.removeWhere((request) =>
          _pair(request.senderId, request.receiverId) == _pair(from, to));
    } else {
      requests
          .add(FriendRequest(senderId: from, receiverId: to, createdAt: now));
    }
  }

  void acceptInviteLink({required String inviter, required String invitee}) =>
      friendships.add(_pair(inviter, invitee));
}

class ProfileView {
  const ProfileView(
      {required this.name,
      required this.rank,
      this.age,
      this.photo,
      this.gamesWon,
      this.gamesPlayed,
      this.badges,
      this.streak,
      this.upcomingGames});
  final String name;
  final String rank;
  final int? age;
  final String? photo;
  final int? gamesWon;
  final int? gamesPlayed;
  final List<String>? badges;
  final int? streak;
  final List<String>? upcomingGames;
}
