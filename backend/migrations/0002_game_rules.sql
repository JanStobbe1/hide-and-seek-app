-- Organizer-controlled game rules introduced after the initial schema.
ALTER TABLE games ADD COLUMN seekers_count INTEGER NOT NULL DEFAULT 1;
ALTER TABLE games ADD COLUMN hiders_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE games ADD COLUMN role_switch_enabled INTEGER NOT NULL DEFAULT 0;
ALTER TABLE games ADD COLUMN stobbe_powers_enabled INTEGER NOT NULL DEFAULT 0;
