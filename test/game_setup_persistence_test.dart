import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verstobbertje/data/backend_api_client.dart';
import 'package:verstobbertje/domain/game_setup.dart';
import 'package:verstobbertje/domain/models.dart';
import 'package:verstobbertje/services/area_lookup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const boundary = [
    AreaPoint(52.5, 5.7),
    AreaPoint(52.5, 5.72),
    AreaPoint(52.52, 5.72),
    AreaPoint(52.52, 5.7)
  ];
  const questions = ['Een?', 'Twee?', 'Drie?'];
  const area = SearchArea(
      country: 'Nederland',
      province: 'Flevoland',
      city: 'Dronten',
      neighbourhood: 'Alle',
      specificArea: 'Park',
      boundary: boundary);

  test('client sends custom settings and restores stored JSON after reopening',
      () async {
    SharedPreferences.setMockInitialValues({});
    final stored = {
      'id': 'game',
      'name': 'Testspel',
      'starts_at': '2026-12-01T12:00:00Z',
      'question_count': 3,
      'custom_questions': jsonEncode(questions),
      'play_boundary': jsonEncode(boundary.map((p) => p.toJson()).toList()),
    };
    final api = BackendApiClient(
      baseUri: Uri.parse('https://test.invalid'),
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/player')) {
          return http.Response(
              '{"player":{"id":"p","profileName":"Noor"},"token":"test"}', 201);
        }
        if (request.method == 'POST') {
          final sent = jsonDecode(request.body) as Map<String, dynamic>;
          expect(sent['customQuestions'], questions);
          expect(
              sent['playBoundary'], boundary.map((p) => p.toJson()).toList());
          return http.Response(jsonEncode({'game': stored}), 201);
        }
        return http.Response(
            jsonEncode({
              'games': [
                stored,
                {
                  'id': 'old',
                  'starts_at': '2026-12-01T12:00:00Z',
                }
              ]
            }),
            200);
      }),
    );
    await api.registerPlayer('Noor');
    final created = await api.createGame(Game(
        id: 'game',
        name: 'Testspel',
        organizer: 'Noor',
        description: '',
        area: area,
        status: GameStatus.available,
        duration: const Duration(hours: 1),
        participants: 1,
        maxParticipants: 10,
        distanceKm: 0,
        startCondition: StartCondition.scheduled,
        scheduledStart: DateTime(2026, 12, 1),
        rules: const GameRules(customQuestions: questions)));
    expect(created.area.boundary.first.latitude, 52.5);
    final reloaded = await api.fetchAvailableGames();
    expect(reloaded.first.rules.customQuestions, questions);
    expect(reloaded.first.area.boundary.map((p) => p.toJson()),
        boundary.map((p) => p.toJson()));
    expect(reloaded.last.rules.customQuestions, isEmpty);
    expect(reloaded.last.area.boundary, isEmpty);
  });

  test('lookup uses actual extent and caches repeated requests', () async {
    var calls = 0;
    final lookup = AreaLookup(client: MockClient((request) async {
      calls++;
      expect(request.url.queryParameters['q'], 'Dronten, Flevoland, Nederland');
      return http.Response(
          jsonEncode({
            'features': [
              {
                'properties': {
                  'countrycode': 'NL',
                  'extent': [5.5112942, 52.6635561, 5.8645023, 52.3641296],
                }
              }
            ]
          }),
          200);
    }));
    final found = await lookup.find(area);
    expect(found.first.latitude, 52.3641296);
    expect(found[2].longitude, 5.8645023);
    expect(validatePlayBoundary(found), isNull);
    await lookup.find(area);
    expect(calls, 1);
    lookup.dispose();
  });

  test('lookup does not substitute a made-up region on failure', () async {
    final lookup = AreaLookup(
        client: MockClient((_) async => http.Response('{"features":[]}', 200)));
    await expectLater(lookup.find(area), throwsFormatException);
    lookup.dispose();
  });
}
