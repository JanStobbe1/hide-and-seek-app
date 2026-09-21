enum FriendDecision { pending, friends, rejected, blocked, expired }

class FriendRequest {
  FriendRequest({
    required this.sender,
    required this.receiver,
    required this.createdAt,
  });
  final String sender, receiver;
  final DateTime createdAt;
  FriendDecision decision = FriendDecision.pending;
}

class FriendshipService {
  final Set<String> friendships = {};
  final Map<String, FriendRequest> requests = {};
  String _pair(String a, String b) => ([a, b]..sort()).join('::');
  FriendDecision choose({
    required String from,
    required String to,
    required DateTime now,
  }) {
    final reverse = requests['$to->$from'];
    if (reverse != null &&
        reverse.decision == FriendDecision.pending &&
        now.difference(reverse.createdAt) <= const Duration(days: 2)) {
      reverse.decision = FriendDecision.friends;
      friendships.add(_pair(from, to));
      return FriendDecision.friends;
    }
    requests.putIfAbsent(
      '$from->$to',
      () => FriendRequest(sender: from, receiver: to, createdAt: now),
    );
    return FriendDecision.pending;
  }

  FriendDecision accept(FriendRequest request, DateTime now) {
    if (now.difference(request.createdAt) > const Duration(days: 2)) {
      request.decision = FriendDecision.expired;
      return request.decision;
    }
    if (request.decision == FriendDecision.pending) {
      request.decision = FriendDecision.friends;
      friendships.add(_pair(request.sender, request.receiver));
    }
    return request.decision;
  }

  FriendDecision reject(FriendRequest request) {
    if (request.decision == FriendDecision.pending) {
      request.decision = FriendDecision.rejected;
    }
    return request.decision;
  }

  FriendDecision block(FriendRequest request) {
    request.decision = FriendDecision.blocked;
    requests.remove('${request.sender}->${request.receiver}');
    requests.remove('${request.receiver}->${request.sender}');
    friendships.remove(_pair(request.sender, request.receiver));
    return request.decision;
  }

  bool canWithdraw(FriendRequest request) => false;

  void invite({required String inviter, required String invitee}) =>
      friendships.add(_pair(inviter, invitee));
}
