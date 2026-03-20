-- C1 fix: Allow multiple delivery rows per order (reassignment creates new rows)
ALTER TABLE deliveries DROP CONSTRAINT IF EXISTS deliveries_order_id_key;
CREATE INDEX IF NOT EXISTS idx_deliveries_order_id ON deliveries (order_id);
