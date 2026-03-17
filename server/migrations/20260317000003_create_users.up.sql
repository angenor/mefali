CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100),
    role user_role NOT NULL,
    status user_status NOT NULL DEFAULT 'active',
    city_id UUID REFERENCES city_config(id),
    fcm_token TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_city_id ON users(city_id);
CREATE INDEX idx_users_role ON users(role);

CREATE TRIGGER set_updated_at BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
