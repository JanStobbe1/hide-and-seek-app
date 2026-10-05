Future<Map<String, dynamic>> enableNearbyPush(String publicKey) =>
    Future.error(UnsupportedError('Pushmeldingen zijn niet beschikbaar.'));

Future<Map<String, dynamic>> refreshNearbyPushLocation() =>
    Future.error(UnsupportedError('Pushmeldingen zijn niet beschikbaar.'));

Future<bool> hasNearbyPushSubscription() async => false;

Future<String?> disableNearbyPush() async => null;
