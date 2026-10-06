-- Store qualifying completed participations and the player's milestone feedback.
-- Participation qualifies after ten minutes elapsed from the later of joining or game start.
ALTER TABLE game_players ADD COLUMN completed_at TEXT;
ALTER TABLE game_players ADD COLUMN extended_completed_at TEXT;

CREATE TABLE IF NOT EXISTS player_feedback (
  player_id TEXT NOT NULL,
  milestone INTEGER NOT NULL CHECK (milestone IN (2, 10, 50)),
  status TEXT NOT NULL CHECK (status IN ('submitted', 'skipped')),
  rating INTEGER CHECK (rating IS NULL OR rating BETWEEN 1 AND 5),
  topic TEXT CHECK (topic IS NULL OR topic IN ('gameplay', 'map', 'powers', 'other')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (player_id, milestone),
  FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_game_players_extended_completed
  ON game_players(extended_completed_at);
CREATE INDEX IF NOT EXISTS idx_player_feedback_milestone
  ON player_feedback(milestone, status);
