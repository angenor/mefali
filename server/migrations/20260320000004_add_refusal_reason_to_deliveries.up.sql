-- M7 fix: Persist refusal reason in DB for analytics
ALTER TABLE deliveries ADD COLUMN refusal_reason TEXT;
