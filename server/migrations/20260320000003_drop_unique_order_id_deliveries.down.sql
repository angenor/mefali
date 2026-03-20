DROP INDEX IF EXISTS idx_deliveries_order_id;
-- Re-add UNIQUE only if no duplicate order_ids exist
ALTER TABLE deliveries ADD CONSTRAINT deliveries_order_id_key UNIQUE (order_id);
