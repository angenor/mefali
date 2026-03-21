-- Add referral system to users table
ALTER TABLE users ADD COLUMN referral_code VARCHAR(8) UNIQUE;
ALTER TABLE users ADD COLUMN referred_by UUID REFERENCES users(id);

-- Backfill existing users with deterministic unique 6-char codes
-- Uses id::TEXT as seed for reproducible results across migration reruns
UPDATE users SET referral_code = UPPER(SUBSTR(MD5(id::TEXT), 1, 6))
WHERE referral_code IS NULL;

-- Handle potential collisions by appending row offset to seed
DO $$
DECLARE
  dup_count INT;
  attempt INT := 0;
BEGIN
  LOOP
    SELECT COUNT(*) INTO dup_count
    FROM (SELECT referral_code FROM users GROUP BY referral_code HAVING COUNT(*) > 1) dupes;
    EXIT WHEN dup_count = 0;
    attempt := attempt + 1;
    UPDATE users u SET referral_code = UPPER(SUBSTR(MD5(u.id::TEXT || attempt::TEXT), 1, 6))
    WHERE u.id IN (
      SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY referral_code ORDER BY created_at) rn
        FROM users
      ) t WHERE rn > 1
    );
  END LOOP;
END $$;

-- Make NOT NULL after backfill
ALTER TABLE users ALTER COLUMN referral_code SET NOT NULL;

-- Index for fast lookup by referral code
CREATE UNIQUE INDEX idx_users_referral_code ON users (referral_code);
