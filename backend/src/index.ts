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
      "access-control-allow-methods": "GET, POST, OPTIONS",
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
  const value = request.headers.get("authorization")?.replace(/^Bearer\\s+/i, "");
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

  const gameMatch = path.match(/^\/api\/v1\/games\/([^/]+)$/);
  if (request.method === "GET" && gameMatch) {
    const game = await env.DB.prepare(
      "SELECT id, status, starts_at, ends_at, created_at, paused_at, stopped_at FROM games WHERE id = ?",
    ).bind(gameMatch[1]).first();
    if (!game) return json({ error: "game_not_found" }, 404, origin);
    return json({ game }, 200, origin);
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
};
