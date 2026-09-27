ALTER TABLE players ADD COLUMN last_activity_at TEXT;

UPDATE players
SET last_activity_at = created_at
WHERE last_activity_at IS NULL;
