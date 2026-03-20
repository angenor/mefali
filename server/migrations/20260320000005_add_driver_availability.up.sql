-- Add driver availability flag to users table.
-- Drivers default to available (true). Non-driver users ignore this column.
ALTER TABLE users ADD COLUMN is_available BOOLEAN NOT NULL DEFAULT true;
