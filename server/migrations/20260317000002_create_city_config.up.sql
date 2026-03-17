CREATE TABLE city_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    city_name VARCHAR(100) NOT NULL UNIQUE,
    delivery_multiplier NUMERIC(5,2) NOT NULL DEFAULT 1.00,
    zones_geojson JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER set_updated_at BEFORE UPDATE ON city_config
FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
