-- Additive migration: older games continue to load with empty custom settings.
ALTER TABLE games ADD COLUMN play_boundary TEXT NOT NULL DEFAULT '[]';
ALTER TABLE games ADD COLUMN custom_questions TEXT NOT NULL DEFAULT '[]';
