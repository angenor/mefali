CREATE TABLE stock_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    alert_type VARCHAR(50) NOT NULL DEFAULT 'below_20_percent',
    current_stock INT NOT NULL,
    initial_stock INT NOT NULL,
    triggered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    acknowledged_at TIMESTAMPTZ
);

CREATE INDEX idx_stock_alerts_merchant_id ON stock_alerts(merchant_id);
CREATE INDEX idx_stock_alerts_product_id ON stock_alerts(product_id);
