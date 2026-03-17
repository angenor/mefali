CREATE TABLE merchants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    address TEXT,
    availability_status vendor_status NOT NULL DEFAULT 'closed',
    city_id UUID REFERENCES city_config(id),
    consecutive_no_response INT NOT NULL DEFAULT 0,
    photo_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_merchants_city_id ON merchants(city_id);
CREATE INDEX idx_merchants_availability_status ON merchants(availability_status);

CREATE TRIGGER set_updated_at BEFORE UPDATE ON merchants
FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
