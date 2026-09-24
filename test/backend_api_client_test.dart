import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:verstobbertje/data/backend_api_client.dart';

void main() {
  test('registers a player and authenticates subsequent events', () async {
    final client = QueueClient([
      http.Response(
        '{"player":{"id":"p1","profileName":"Noor"},"token":"token-1"}',
        201,
      ),
      http.Response('{"accepted":true,"duplicate":false}', 202),
    ]);
    final api = BackendApiClient(
      baseUri: Uri.parse('https://api.example.test'),
      client: client,
    );

    final session = await api.registerPlayer('Noor');
    await api.sendGameEvent(
      gameId: 'game-1',
      eventType: 'power_used',
      occurredAt: '2026-09-24T08:00:00Z',
      idempotencyKey: 'event-1',
      playerId: session.playerId,
    );

    expect(session.playerId, 'p1');
    expect(client.requests[0].url.path, '/api/v1/auth/player');
    expect(client.requests[1].url.path, '/api/v1/games/game-1/events');
    expect(client.requests[1].headers['authorization'], 'Bearer token-1');
    expect(client.requests[1].headers['idempotency-key'], 'event-1');
  });

  test('does not send events before a player session exists', () async {
    final api = BackendApiClient(
      baseUri: Uri.parse('https://api.example.test'),
      client: QueueClient(const []),
    );

    await expectLater(
      api.sendGameEvent(
        gameId: 'game-1',
        eventType: 'test',
        occurredAt: '2026-09-24T08:00:00Z',
        idempotencyKey: 'event-1',
      ),
      throwsA(
        isA<BackendApiException>().having(
          (error) => error.code,
          'code',
          'player_session_required',
        ),
      ),
    );
  });
}

class QueueClient extends http.BaseClient {
  QueueClient(this.responses);

  final List<http.Response> responses;
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final response = responses.removeAt(0);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
