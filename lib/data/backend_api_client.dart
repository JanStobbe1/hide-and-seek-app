import 'dart:convert';

import 'package:http/http.dart' as http;

class PlayerSession {
  const PlayerSession({
    required this.playerId,
    required this.profileName,
    required this.token,
  });

  final String playerId;
  final String profileName;
  final String token;
}

class BackendApiException implements Exception {
  const BackendApiException(this.statusCode, this.code);

  final int statusCode;
  final String code;

  @override
  String toString() => 'BackendApiException($statusCode, $code)';
}

class BackendApiClient {
  BackendApiClient({
    required Uri baseUri,
    http.Client? client,
  })  : baseUri = baseUri,
        client = client ?? http.Client();

  final Uri baseUri;
  final http.Client client;
  String? _playerToken;

  Uri _endpoint(String path) => baseUri.replace(
        path: '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}$path',
      );

  Future<PlayerSession> registerPlayer(String profileName) async {
    final response = await client.post(
      _endpoint('/api/v1/auth/player'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'profileName': profileName}),
    );
    final data = _decode(response);
    final player = data['player'];
    final token = data['token'];
    if (player is! Map<String, dynamic> || token is! String) {
      throw const BackendApiException(502, 'invalid_session_response');
    }
    final playerId = player['id'];
    final returnedName = player['profileName'];
    if (playerId is! String || returnedName is! String) {
      throw const BackendApiException(502, 'invalid_player_response');
    }
    _playerToken = token;
    return PlayerSession(
      playerId: playerId,
      profileName: returnedName,
      token: token,
    );
  }

  Future<void> sendGameEvent({
    required String gameId,
    required String eventType,
    required String occurredAt,
    required String idempotencyKey,
    String? playerId,
    Map<String, dynamic> payload = const {},
  }) async {
    final token = _playerToken;
    if (token == null) {
      throw const BackendApiException(401, 'player_session_required');
    }
    final response = await client.post(
      _endpoint('/api/v1/games/$gameId/events'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
        'idempotency-key': idempotencyKey,
      },
      body: jsonEncode({
        'eventType': eventType,
        'occurredAt': occurredAt,
        if (playerId != null) 'playerId': playerId,
        'payload': payload,
      }),
    );
    _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = data['error'];
      throw BackendApiException(
        response.statusCode,
        code is String ? code : 'request_failed',
      );
    }
    return data;
  }

  void dispose() => client.close();
}
