ALTER TABLE games ADD COLUMN start_notifications_sent_at TEXT;

CREATE TABLE IF NOT EXISTS push_subscriptions (
  id TEXT PRIMARY KEY,
  player_id TEXT NOT NULL,
  endpoint TEXT NOT NULL UNIQUE,
  p256dh TEXT NOT NULL,
  auth TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  radius_km REAL NOT NULL DEFAULT 25 CHECK (radius_km BETWEEN 1 AND 100),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_push_subscriptions_player
  ON push_subscriptions(player_id);
CREATE INDEX IF NOT EXISTS idx_games_start_notifications
  ON games(status, starts_at, start_notifications_sent_at);
