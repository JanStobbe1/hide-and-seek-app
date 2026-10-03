import { validateGameSetup } from "./game-setup.js";

export interface Env {
  DB: D1Database;
  ADMIN_API_TOKEN: string;
  PLAYER_TOKEN_SECRET: string;
  ALLOWED_ORIGIN?: string;
}

type JsonObject = Record<string, unknown>;

const json = (body: unknown, status = 200, origin = "*") =>
  new Response(status === 204 ? null : JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "access-control-allow-origin": origin,
      "access-control-allow-headers": "authorization, content-type, idempotency-key",
      "access-control-allow-methods": "GET, POST, DELETE, OPTIONS",
    },
  });

const parseBody = async (request: Request): Promise<JsonObject> => {
  try {
    const value = await request.json();
    return value && typeof value === "object" ? value as JsonObject : {};
  } catch {
    return {};
  }
};

const isAdmin = (request: Request, env: Env) =>
  Boolean(env.ADMIN_API_TOKEN) &&
  request.headers.get("authorization") === `Bearer ${env.ADMIN_API_TOKEN}`;

const encoder = new TextEncoder();

const base64Url = (bytes: ArrayBuffer | Uint8Array) =>
  btoa(String.fromCharCode(...new Uint8Array(bytes)))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");

const fromBase64Url = (value: string) => {
  const padded = value.replaceAll("-", "+").replaceAll("_", "/")
    + "=".repeat((4 - value.length % 4) % 4);
  return Uint8Array.from(atob(padded), (character) => character.charCodeAt(0));
};

const hmac = async (secret: string, value: string) => {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
  return new Uint8Array(await crypto.subtle.sign("HMAC", key, encoder.encode(value)));
};

const createPlayerToken = async (env: Env, playerId: string) => {
  const header = base64Url(encoder.encode(JSON.stringify({ alg: "HS256", typ: "JWT" })));
  const payload = base64Url(encoder.encode(JSON.stringify({
    sub: playerId,
    scope: "player",
    exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 30,
  })));
  const unsigned = `${header}.${payload}`;
  return `${unsigned}.${base64Url(await hmac(env.PLAYER_TOKEN_SECRET, unsigned))}`;
};

const playerFromToken = async (request: Request, env: Env) => {
  const value = request.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!value) return null;
  const parts = value.split(".");
  if (parts.length !== 3) return null;
  const unsigned = `${parts[0]}.${parts[1]}`;
  const expected = await hmac(env.PLAYER_TOKEN_SECRET, unsigned);
  const actual = fromBase64Url(parts[2]);
  if (actual.length !== expected.length) return null;
  let valid = true;
  for (let i = 0; i < expected.length; i += 1) valid = valid && actual[i] === expected[i];
  if (!valid) return null;
  try {
    const payload = JSON.parse(new TextDecoder().decode(fromBase64Url(parts[1])));
    return payload.scope === "player" && payload.exp > Math.floor(Date.now() / 1000)
      ? String(payload.sub)
      : null;
  } catch {
    return null;
  }
};

const touchPlayer = async (env: Env, playerId: string) => {
  await env.DB.prepare(
    "UPDATE players SET last_activity_at = CURRENT_TIMESTAMP WHERE id = ?",
  ).bind(playerId).run();
};

const purgeInactivePlayers = async (env: Env) => {
  await env.DB.batch([
    env.DB.prepare(
      "UPDATE games SET created_by = NULL WHERE created_by IN "
      + "(SELECT id FROM players WHERE COALESCE(last_activity_at, created_at) < datetime('now', '-12 months'))",
    ),
    env.DB.prepare(
      "UPDATE game_events SET player_id = NULL WHERE player_id IN "
      + "(SELECT id FROM players WHERE COALESCE(last_activity_at, created_at) < datetime('now', '-12 months'))",
    ),
    env.DB.prepare(
      "DELETE FROM players WHERE COALESCE(last_activity_at, created_at) < datetime('now', '-12 months')",
    ),
  ]);
};

const audit = async (
  env: Env,
  adminId: string,
  action: string,
  resourceType: string,
  resourceId: string | null,
  reason: string,
) => {
  await env.DB.prepare(
    "INSERT INTO audit_log (admin_id, action, resource_type, resource_id, reason) VALUES (?, ?, ?, ?, ?)",
  ).bind(adminId, action, resourceType, resourceId, reason).run();
};

const route = async (request: Request, env: Env): Promise<Response> => {
  const origin = env.ALLOWED_ORIGIN ?? "*";
  const url = new URL(request.url);
  const path = url.pathname;

  if (request.method === "OPTIONS") return json({}, 204, origin);
  if (request.method === "GET" && path === "/api/health") {
    return json({ ok: true, service: "verstobbertje-api" }, 200, origin);
  }

  if (request.method === "POST" && path === "/api/v1/auth/player") {
    if (!env.PLAYER_TOKEN_SECRET) return json({ error: "player_auth_not_configured" }, 503, origin);
    const body = await parseBody(request);
    const profileName = typeof body.profileName === "string" ? body.profileName.trim() : "";
    if (profileName.length < 2 || profileName.length > 30) {
      return json({ error: "profile_name_invalid" }, 400, origin);
    }
    const playerId = crypto.randomUUID();
    await env.DB.batch([
      env.DB.prepare("INSERT INTO players (id, profile_name) VALUES (?, ?)").bind(playerId, profileName),
      env.DB.prepare("INSERT INTO subscriptions (player_id) VALUES (?)").bind(playerId),
    ]);
    const token = await createPlayerToken(env, playerId);
    return json({ player: { id: playerId, profileName }, token }, 201, origin);
  }

  if (request.method === "GET" && path === "/api/v1/player/games") {
    const authenticatedPlayer = await playerFromToken(request, env);
    if (!authenticatedPlayer) return json({ error: "unauthorized" }, 401, origin);
    await touchPlayer(env, authenticatedPlayer);
    const games = await env.DB.prepare(
      `SELECT g.id, g.name, g.description,
        CASE WHEN g.status = 'scheduled'
          AND datetime(g.starts_at) <= CURRENT_TIMESTAMP
          AND datetime(g.ends_at) > CURRENT_TIMESTAMP
          THEN 'active' ELSE g.status END AS status,
        g.starts_at, g.ends_at, g.created_at, g.created_by,
        g.country, g.province, g.city, g.neighbourhood, g.specific_area,
        g.duration_minutes, g.max_participants, g.distance_km,
        g.start_condition, g.participant_threshold, g.is_public,
        g.hints_enabled, g.questions_enabled, g.question_count,
        g.custom_questions, g.play_boundary, g.game_type,
        g.allow_rejoin_after_found, g.seekers_count, g.hiders_count,
        g.role_switch_enabled, g.stobbe_powers_enabled,
        COUNT(all_players.player_id) AS participant_count
       FROM game_players mine
       JOIN games g ON g.id = mine.game_id
       LEFT JOIN game_players all_players
         ON all_players.game_id = g.id AND all_players.left_at IS NULL
       WHERE mine.player_id = ? AND mine.left_at IS NULL
         AND g.status IN ('scheduled', 'active')
         AND (g.ends_at IS NULL OR datetime(g.ends_at) > CURRENT_TIMESTAMP)
       GROUP BY g.id
       ORDER BY g.starts_at ASC
       LIMIT 100`,
    ).bind(authenticatedPlayer).all();
    return json({ games: games.results }, 200, origin);
  }

  if (request.method === "GET" && path === "/api/v1/games") {
    const games = await env.DB.prepare(
      `SELECT g.id, g.name, g.description,\n        CASE WHEN g.status = 'scheduled'\n          AND datetime(g.starts_at) <= CURRENT_TIMESTAMP\n          AND datetime(g.ends_at) > CURRENT_TIMESTAMP\n          THEN 'active' ELSE g.status END AS status,\n        g.starts_at, g.ends_at,
        g.created_at, g.created_by, g.country, g.province, g.city,
        g.neighbourhood, g.specific_area, g.duration_minutes,
        g.max_participants, g.distance_km, g.start_condition,
        g.participant_threshold, g.is_public, g.hints_enabled,
        g.questions_enabled, g.question_count, g.custom_questions, g.play_boundary, g.game_type, g.allow_rejoin_after_found,
        g.seekers_count, g.hiders_count, g.role_switch_enabled, g.stobbe_powers_enabled,
        COUNT(gp.player_id) AS participant_count
       FROM games g
       LEFT JOIN game_players gp ON gp.game_id = g.id AND gp.left_at IS NULL
       WHERE g.is_public = 1
         AND g.status IN ('scheduled', 'active')
         AND (g.ends_at IS NULL OR datetime(g.ends_at) > CURRENT_TIMESTAMP)
       GROUP BY g.id
       ORDER BY g.starts_at ASC
       LIMIT 100`,
    ).all();
    return json({ games: games.results }, 200, origin);
  }

  if (request.method === "POST" && path === "/api/v1/games") {
    const authenticatedPlayer = await playerFromToken(request, env);
    if (!authenticatedPlayer) return json({ error: "unauthorized" }, 401, origin);
    const body = await parseBody(request);
    const setupError = validateGameSetup(body);
    if (setupError) return json({ error: setupError }, 400, origin);
    const name = typeof body.name === "string" ? body.name.trim() : "";
    const startsAt = typeof body.startsAt === "string" ? body.startsAt : "";
    const maxParticipants = Number(body.maxParticipants);
    const durationMinutes = Number(body.durationMinutes);
    if (!name || !startsAt || !Number.isFinite(maxParticipants) ||
        !Number.isFinite(durationMinutes)) {
      return json({ error: "game_fields_required" }, 400, origin);
    }
    const gameId = typeof body.id === "string" && body.id.trim()
      ? body.id.trim()
      : crypto.randomUUID();
    const game = {
      id: gameId,
      name,
      description: typeof body.description === "string" ? body.description : "",
      status: "scheduled",
      starts_at: startsAt,
      ends_at: new Date(Date.parse(startsAt) + durationMinutes * 60000).toISOString(),
      created_by: authenticatedPlayer,
      country: typeof body.country === "string" ? body.country : "",
      province: typeof body.province === "string" ? body.province : "",
      city: typeof body.city === "string" ? body.city : "",
      neighbourhood: typeof body.neighbourhood === "string" ? body.neighbourhood : "",
      specific_area: typeof body.specificArea === "string" ? body.specificArea : "",
      duration_minutes: durationMinutes,
      max_participants: maxParticipants,
      distance_km: Number(body.distanceKm) || 0,
      start_condition: typeof body.startCondition === "string"
        ? body.startCondition : "scheduled",
      participant_threshold: body.participantThreshold == null
        ? null : Number(body.participantThreshold),
      is_public: body.isPublic === false ? 0 : 1,
      hints_enabled: body.hintsEnabled === false ? 0 : 1,
      questions_enabled: body.questionsEnabled === false ? 0 : 1,
      play_boundary: JSON.stringify(body.playBoundary ?? []),
      custom_questions: JSON.stringify(Array.isArray(body.customQuestions)
        ? body.customQuestions.map(q => (q as string).trim()) : []),
      question_count: Math.min(5, Math.max(3, Number(body.questionCount) || 3)),
      game_type: typeof body.gameType === "string" ? body.gameType : "classic",
      allow_rejoin_after_found: body.allowRejoinAfterFound === true ? 1 : 0,
      seekers_count: Number(body.seekersCount) || 1,
      hiders_count: Number(body.hidersCount) || 0,
      role_switch_enabled: body.roleSwitchEnabled === true ? 1 : 0,
      stobbe_powers_enabled: body.stobbePowersEnabled === true ? 1 : 0,
    };
    await env.DB.batch([
      env.DB.prepare(
        `INSERT INTO games
          (id, name, description, status, starts_at, ends_at, created_by,
           country, province, city, neighbourhood, specific_area,
           duration_minutes, max_participants, distance_km, start_condition,
           participant_threshold, is_public, hints_enabled, questions_enabled,
           question_count, play_boundary, custom_questions, game_type, allow_rejoin_after_found,
           seekers_count, hiders_count, role_switch_enabled, stobbe_powers_enabled)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      ).bind(
        game.id, game.name, game.description, game.status, game.starts_at,
        game.ends_at, game.created_by, game.country, game.province, game.city,
        game.neighbourhood, game.specific_area, game.duration_minutes,
        game.max_participants, game.distance_km, game.start_condition,
        game.participant_threshold, game.is_public, game.hints_enabled,
        game.questions_enabled, game.question_count, game.play_boundary, game.custom_questions, game.game_type, game.allow_rejoin_after_found,
        game.seekers_count, game.hiders_count, game.role_switch_enabled,
        game.stobbe_powers_enabled,
      ),
      env.DB.prepare(
        "INSERT INTO game_players (game_id, player_id, role) VALUES (?, ?, 'host')",
      ).bind(game.id, authenticatedPlayer),
    ]);
    return json({ game: { ...game, participant_count: 1 } }, 201, origin);
  }

  const gameMatch = path.match(/^\/api\/v1\/games\/([^/]+)$/);
  if (request.method === "GET" && gameMatch) {
    const game = await env.DB.prepare(
      `SELECT g.id, g.name, g.description,
        CASE WHEN g.status = 'scheduled'
          AND datetime(g.starts_at) <= CURRENT_TIMESTAMP
          AND datetime(g.ends_at) > CURRENT_TIMESTAMP
          THEN 'active' ELSE g.status END AS status,
        g.starts_at, g.ends_at, g.created_by, g.created_at,
        g.paused_at, g.stopped_at, g.country, g.province, g.city,
        g.neighbourhood, g.specific_area, g.duration_minutes,
        g.max_participants, g.distance_km, g.start_condition,
        g.participant_threshold, g.is_public, g.hints_enabled,
        g.questions_enabled, g.question_count, g.custom_questions, g.play_boundary, g.game_type, g.allow_rejoin_after_found,
        g.seekers_count, g.hiders_count, g.role_switch_enabled, g.stobbe_powers_enabled,
        COUNT(gp.player_id) AS participant_count
       FROM games g
       LEFT JOIN game_players gp ON gp.game_id = g.id AND gp.left_at IS NULL
       WHERE g.id = ?
       GROUP BY g.id`,
    ).bind(gameMatch[1]).first();
    if (!game) return json({ error: "game_not_found" }, 404, origin);
    return json({ game }, 200, origin);
  }

  const participantsMatch = path.match(/^\/api\/v1\/games\/([^/]+)\/participants$/);
  if (request.method === "GET" && participantsMatch) {
    const participants = await env.DB.prepare(
      `SELECT p.profile_name AS name
       FROM game_players gp
       JOIN players p ON p.id = gp.player_id
       WHERE gp.game_id = ? AND gp.left_at IS NULL
       ORDER BY gp.joined_at ASC`,
    ).bind(participantsMatch[1]).all();
    return json({ participants: participants.results }, 200, origin);
  }

  const joinMatch = path.match(/^\/api\/v1\/games\/([^/]+)\/join$/);
  if (request.method === "POST" && joinMatch) {
    const authenticatedPlayer = await playerFromToken(request, env);
    if (!authenticatedPlayer) return json({ error: "unauthorized" }, 401, origin);
    const game = await env.DB.prepare(
      "SELECT id, status, starts_at, max_participants, is_public FROM games WHERE id = ?",
    ).bind(joinMatch[1]).first();
    if (!game || Number(game.is_public) !== 1) {
      return json({ error: "game_not_found" }, 404, origin);
    }
    const startsAt = Date.parse(String(game.starts_at));
    if (!Number.isFinite(startsAt) || Date.now() > startsAt + 5 * 60 * 1000) {
      return json({ error: "join_window_closed" }, 409, origin);
    }
    const count = await env.DB.prepare(
      "SELECT COUNT(*) AS count FROM game_players WHERE game_id = ? AND left_at IS NULL",
    ).bind(joinMatch[1]).first();
    if (Number(count?.count ?? 0) >= Number(game.max_participants)) {
      return json({ error: "game_full" }, 409, origin);
    }
    await env.DB.prepare(
      "INSERT OR IGNORE INTO game_players (game_id, player_id, role) VALUES (?, ?, 'player')",
    ).bind(joinMatch[1], authenticatedPlayer).run();
    await touchPlayer(env, authenticatedPlayer);
    return json({ joined: true, gameId: joinMatch[1] }, 200, origin);
  }

  if (request.method === "DELETE" && path === "/api/v1/account") {
    const authenticatedPlayer = await playerFromToken(request, env);
    if (!authenticatedPlayer) return json({ error: "unauthorized" }, 401, origin);
    await env.DB.batch([
      env.DB.prepare("UPDATE games SET created_by = NULL WHERE created_by = ?")
        .bind(authenticatedPlayer),
      env.DB.prepare("DELETE FROM players WHERE id = ?").bind(authenticatedPlayer),
    ]);
    return json({}, 204, origin);
  }

  const withdrawMatch = path.match(/^\/api\/v1\/games\/([^/]+)\/withdraw$/);
  if (request.method === "POST" && withdrawMatch) {
    const authenticatedPlayer = await playerFromToken(request, env);
    if (!authenticatedPlayer) return json({ error: "unauthorized" }, 401, origin);
    const game = await env.DB.prepare(
      "SELECT id, status, starts_at, created_by FROM games WHERE id = ?",
    ).bind(withdrawMatch[1]).first();
    if (!game) return json({ error: "game_not_found" }, 404, origin);
    if (String(game.created_by) !== authenticatedPlayer) {
      return json({ error: "organizer_required" }, 403, origin);
    }
    if (String(game.status) !== "scheduled") {
      return json({ error: "game_not_withdrawable" }, 409, origin);
    }
    const startsAt = Date.parse(String(game.starts_at));
    if (!Number.isFinite(startsAt) || Date.now() > startsAt - 5 * 60 * 1000) {
      return json({ error: "withdrawal_window_closed" }, 409, origin);
    }
    await env.DB.prepare(
      "UPDATE games SET status = 'stopped', stopped_at = CURRENT_TIMESTAMP WHERE id = ?",
    ).bind(withdrawMatch[1]).run();
    return json({ withdrawn: true, gameId: withdrawMatch[1] }, 200, origin);
  }

  const eventMatch = path.match(/^\/api\/v1\/games\/([^/]+)\/events$/);
  if (request.method === "POST" && eventMatch) {
    const authenticatedPlayer = await playerFromToken(request, env);
    if (!authenticatedPlayer) return json({ error: "unauthorized" }, 401, origin);
    const idempotencyKey = request.headers.get("idempotency-key");
    if (!idempotencyKey) return json({ error: "idempotency_key_required" }, 400, origin);
    const body = await parseBody(request);
    const eventType = typeof body.eventType === "string" ? body.eventType : "";
    const occurredAt = typeof body.occurredAt === "string" ? body.occurredAt : "";
    const playerId = typeof body.playerId === "string" ? body.playerId : authenticatedPlayer;
    if (playerId !== authenticatedPlayer) return json({ error: "player_identity_mismatch" }, 403, origin);
    if (!eventType || !occurredAt) {
      return json({ error: "eventType_and_occurredAt_required" }, 400, origin);
    }
    const result = await env.DB.prepare(
      "INSERT OR IGNORE INTO game_events (game_id, player_id, event_type, idempotency_key, payload_json, occurred_at) VALUES (?, ?, ?, ?, ?, ?)",
    ).bind(
      eventMatch[1],
      playerId,
      eventType,
      idempotencyKey,
      JSON.stringify(body.payload ?? {}),
      occurredAt,
    ).run();
    await touchPlayer(env, authenticatedPlayer);
    return json({ accepted: result.meta.changes === 1, duplicate: result.meta.changes === 0 }, 202, origin);
  }

  if (!path.startsWith("/api/admin/")) return json({ error: "not_found" }, 404, origin);
  if (!isAdmin(request, env)) return json({ error: "unauthorized" }, 401, origin);

  const adminId = "bootstrap-admin";
  if (request.method === "GET" && path === "/api/admin/dashboard") {
    const [games, players, signals, subscriptions] = await Promise.all([
      env.DB.prepare("SELECT status, COUNT(*) AS count FROM games GROUP BY status").all(),
      env.DB.prepare("SELECT status, COUNT(*) AS count FROM players GROUP BY status").all(),
      env.DB.prepare("SELECT severity, COUNT(*) AS count FROM anomaly_signals WHERE status = 'open' GROUP BY severity").all(),
      env.DB.prepare("SELECT plan, status, COUNT(*) AS count FROM subscriptions GROUP BY plan, status").all(),
    ]);
    return json({ games: games.results, players: players.results, signals: signals.results, subscriptions: subscriptions.results }, 200, origin);
  }

  if (request.method === "GET" && path === "/api/admin/games") {
    const games = await env.DB.prepare(
      "SELECT g.id, g.status, g.starts_at, g.ends_at, g.created_at, COUNT(gp.player_id) AS player_count FROM games g LEFT JOIN game_players gp ON gp.game_id = g.id GROUP BY g.id ORDER BY g.created_at DESC LIMIT 100",
    ).all();
    return json({ games: games.results }, 200, origin);
  }

  if (request.method === "GET" && path === "/api/admin/players") {
    const players = await env.DB.prepare(
      "SELECT id, profile_name, status, created_at, blocked_at FROM players ORDER BY created_at DESC LIMIT 100",
    ).all();
    return json({ players: players.results }, 200, origin);
  }

  if (request.method === "GET" && path === "/api/admin/subscriptions") {
    const subscriptions = await env.DB.prepare(
      "SELECT s.player_id, p.profile_name, s.plan, s.status, s.started_at, s.ends_at FROM subscriptions s JOIN players p ON p.id = s.player_id ORDER BY s.started_at DESC LIMIT 100",
    ).all();
    return json({ subscriptions: subscriptions.results }, 200, origin);
  }

  if (request.method === "GET" && path === "/api/admin/signals") {
    const signals = await env.DB.prepare(
      "SELECT id, game_id, player_id, signal_type, severity, details_json, status, created_at FROM anomaly_signals ORDER BY created_at DESC LIMIT 100",
    ).all();
    return json({ signals: signals.results }, 200, origin);
  }

  const reviewMatch = path.match(/^\/api\/admin\/signals\/(\d+)\/review$/);
  if (request.method === "POST" && reviewMatch) {
    const body = await parseBody(request);
    const status = typeof body.status === "string" ? body.status : "reviewed";
    const reason = typeof body.reason === "string" ? body.reason.trim() : "";
    if (!reason) return json({ error: "reason_required" }, 400, origin);
    await env.DB.prepare(
      "UPDATE anomaly_signals SET status = ?, reviewed_by = ?, reviewed_at = CURRENT_TIMESTAMP WHERE id = ?",
    ).bind(status, adminId, reviewMatch[1]).run();
    await audit(env, adminId, "review_signal", "anomaly_signal", reviewMatch[1], reason);
    return json({ ok: true }, 200, origin);
  }

  const gameAction = path.match(/^\/api\/admin\/games\/([^/]+)\/(pause|stop)$/);
  if (request.method === "POST" && gameAction) {
    const body = await parseBody(request);
    const reason = typeof body.reason === "string" ? body.reason.trim() : "";
    if (!reason) return json({ error: "reason_required" }, 400, origin);
    const status = gameAction[2] === "pause" ? "paused" : "stopped";
    const column = gameAction[2] === "pause" ? "paused_at" : "stopped_at";
    await env.DB.prepare(`UPDATE games SET status = ?, ${column} = CURRENT_TIMESTAMP WHERE id = ?`)
      .bind(status, gameAction[1]).run();
    await audit(env, adminId, `${gameAction[2]}_game`, "game", gameAction[1], reason);
    return json({ ok: true, status }, 200, origin);
  }

  const blockMatch = path.match(/^\/api\/admin\/players\/([^/]+)\/block$/);
  if (request.method === "POST" && blockMatch) {
    const body = await parseBody(request);
    const reason = typeof body.reason === "string" ? body.reason.trim() : "";
    if (!reason) return json({ error: "reason_required" }, 400, origin);
    await env.DB.prepare("UPDATE players SET status = 'blocked', blocked_at = CURRENT_TIMESTAMP WHERE id = ?")
      .bind(blockMatch[1]).run();
    await audit(env, adminId, "block_player", "player", blockMatch[1], reason);
    return json({ ok: true, status: "blocked" }, 200, origin);
  }

  return json({ error: "not_found" }, 404, origin);
};

export default {
  fetch(request: Request, env: Env): Promise<Response> {
    return route(request, env);
  },
  scheduled(_event: ScheduledController, env: Env): Promise<void> {
    return purgeInactivePlayers(env);
  },
};
