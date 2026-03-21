-- Add missing description column and UNIQUE constraint on order_id
ALTER TABLE disputes ADD COLUMN description TEXT;
ALTER TABLE disputes ADD CONSTRAINT disputes_order_id_unique UNIQUE (order_id);
