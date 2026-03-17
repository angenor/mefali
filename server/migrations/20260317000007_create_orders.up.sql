CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES users(id),
    merchant_id UUID NOT NULL REFERENCES merchants(id),
    driver_id UUID REFERENCES users(id),
    status order_status NOT NULL DEFAULT 'pending',
    payment_type payment_type NOT NULL,
    payment_status payment_status NOT NULL DEFAULT 'pending',
    subtotal BIGINT NOT NULL CHECK (subtotal >= 0),
    delivery_fee BIGINT NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0),
    total BIGINT NOT NULL CHECK (total >= 0),
    delivery_address TEXT,
    delivery_lat DOUBLE PRECISION,
    delivery_lng DOUBLE PRECISION,
    city_id UUID REFERENCES city_config(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_merchant_id ON orders(merchant_id);
CREATE INDEX idx_orders_driver_id ON orders(driver_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_city_id ON orders(city_id);
CREATE INDEX idx_orders_created_at ON orders(created_at);

CREATE TRIGGER set_updated_at BEFORE UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
