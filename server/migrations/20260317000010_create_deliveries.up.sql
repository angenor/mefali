CREATE TABLE deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL UNIQUE REFERENCES orders(id),
    driver_id UUID NOT NULL REFERENCES users(id),
    status delivery_status NOT NULL DEFAULT 'pending',
    current_lat DOUBLE PRECISION,
    current_lng DOUBLE PRECISION,
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_deliveries_driver_id ON deliveries(driver_id);
CREATE INDEX idx_deliveries_status ON deliveries(status);

CREATE TRIGGER set_updated_at BEFORE UPDATE ON deliveries
FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
