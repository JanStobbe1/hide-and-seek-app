import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

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
    required this.baseUri,
    http.Client? client,
  }) : client = client ?? http.Client();

  final Uri baseUri;
  final http.Client client;
  String? _playerToken;

  Uri _endpoint(String path) => baseUri.replace(
        path: baseUri.path.replaceFirst(RegExp(r'/$'), '') + path,
      );

  Future<PlayerSession?> restorePlayerSession() async {
    final preferences = await SharedPreferences.getInstance();
    final playerId = preferences.getString('verstobbertje.playerId');
    final profileName = preferences.getString('verstobbertje.profileName');
    final token = preferences.getString('verstobbertje.playerToken');
    if (playerId == null || profileName == null || token == null) return null;
    _playerToken = token;
    return PlayerSession(
      playerId: playerId,
      profileName: profileName,
      token: token,
    );
  }

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
    final session = PlayerSession(
      playerId: playerId,
      profileName: returnedName,
      token: token,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('verstobbertje.playerId', session.playerId);
    await preferences.setString(
      'verstobbertje.profileName',
      session.profileName,
    );
    await preferences.setString('verstobbertje.playerToken', session.token);
    return session;
  }

  Future<List<Game>> fetchAvailableGames() async {
    final response = await client.get(_endpoint('/api/v1/games'));
    final data = _decode(response);
    final games = data['games'];
    if (games is! List) return const [];
    return games
        .whereType<Map<String, dynamic>>()
        .map(_gameFromJson)
        .toList(growable: false);
  }

  Future<Game> createGame(Game game) async {
    final token = _playerToken;
    if (token == null) {
      throw const BackendApiException(401, 'player_session_required');
    }
    final startsAt = game.scheduledStart?.toUtc().toIso8601String() ??
        DateTime.now().toUtc().toIso8601String();
    final response = await client.post(
      _endpoint('/api/v1/games'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': game.id,
        'name': game.name,
        'description': game.description,
        'startsAt': startsAt,
        'durationMinutes': game.duration.inMinutes,
        'maxParticipants': game.maxParticipants,
        'distanceKm': game.distanceKm,
        'country': game.area.country,
        'province': game.area.province,
        'city': game.area.city,
        'neighbourhood': game.area.neighbourhood,
        'specificArea': game.area.specificArea,
        'startCondition': game.startCondition.name,
        'participantThreshold': game.participantThreshold,
        'isPublic': game.isPublic,
        'hintsEnabled': game.rules.hintsEnabled,
        'questionsEnabled': game.rules.questionsEnabled,
        'gameType': game.rules.gameType.name,
        'seekersCount': game.rules.seekersCount,
        'hidersCount': game.rules.hidersCount,
        'roleSwitchEnabled': game.rules.roleSwitchEnabled,
        'stobbePowersEnabled': game.rules.stobbePowersEnabled,
        'allowRejoinAfterFound': game.rules.allowRejoinAfterFound,
      }),
    );
    final data = _decode(response);
    final created = data['game'];
    if (created is! Map<String, dynamic>) {
      throw const BackendApiException(502, 'invalid_game_response');
    }
    return _gameFromJson(created);
  }

  Future<void> joinGame(String gameId) async {
    final token = _playerToken;
    if (token == null) {
      throw const BackendApiException(401, 'player_session_required');
    }
    final response = await client.post(
      _endpoint('/api/v1/games/$gameId/join'),
      headers: {
        'authorization': 'Bearer $token',
      },
    );
    _decode(response);
  }

  Game _gameFromJson(Map<String, dynamic> value) {
    final status = switch (value['status']) {
      'active' => GameStatus.active,
      'waiting' => GameStatus.waiting,
      'completed' => GameStatus.completed,
      'abandoned' => GameStatus.abandoned,
      _ => GameStatus.available,
    };
    final startCondition = value['start_condition'] == 'participantCount'
        ? StartCondition.participantCount
        : StartCondition.scheduled;
    final startValue = DateTime.tryParse('${value['starts_at'] ?? ''}');
    final gameType = GameType.values.firstWhere(
      (item) => item.name == value['game_type'],
      orElse: () => GameType.classic,
    );
    int asInt(Object? item, int fallback) =>
        item is num ? item.toInt() : int.tryParse('$item') ?? fallback;
    double asDouble(Object? item, double fallback) =>
        item is num ? item.toDouble() : double.tryParse('$item') ?? fallback;
    final maxParticipants = asInt(value['max_participants'], 24);
    final seekersCount = asInt(value['seekers_count'], 1);
    return Game(
      id: '${value['id']}',
      name: '${value['name'] ?? 'Naamloos spel'}',
      organizer: '${value['organizer'] ?? 'Verstobbertje'}',
      description: '${value['description'] ?? ''}',
      area: SearchArea(
        country: '${value['country'] ?? ''}',
        province: '${value['province'] ?? ''}',
        city: '${value['city'] ?? ''}',
        neighbourhood: '${value['neighbourhood'] ?? ''}',
        specificArea: '${value['specific_area'] ?? ''}',
      ),
      status: status,
      duration: Duration(minutes: asInt(value['duration_minutes'], 120)),
      participants: asInt(value['participant_count'], 0),
      maxParticipants: maxParticipants,
      distanceKm: asDouble(value['distance_km'], 0),
      startCondition: startCondition,
      scheduledStart: startValue,
      participantThreshold: value['participant_threshold'] == null
          ? null
          : asInt(value['participant_threshold'], 1),
      isPublic: value['is_public'] != 0 && value['is_public'] != false,
      rules: GameRules(
        hintsEnabled:
            value['hints_enabled'] != 0 && value['hints_enabled'] != false,
        questionsEnabled: value['questions_enabled'] != 0 &&
            value['questions_enabled'] != false,
        gameType: gameType,
        seekersCount: seekersCount,
        hidersCount: asInt(
          value['hiders_count'],
          (maxParticipants - seekersCount).clamp(0, maxParticipants),
        ),
        roleSwitchEnabled: value['role_switch_enabled'] != 0 &&
            value['role_switch_enabled'] != false,
        stobbePowersEnabled: value['stobbe_powers_enabled'] != 0 &&
            value['stobbe_powers_enabled'] != false,
        allowRejoinAfterFound: value['allow_rejoin_after_found'] != 0 &&
            value['allow_rejoin_after_found'] != false,
      ),
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
