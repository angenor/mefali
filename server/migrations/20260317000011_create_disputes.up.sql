CREATE TABLE disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id),
    reporter_id UUID NOT NULL REFERENCES users(id),
    dispute_type dispute_type NOT NULL,
    status dispute_status NOT NULL DEFAULT 'open',
    resolution TEXT,
    resolved_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_disputes_order_id ON disputes(order_id);
CREATE INDEX idx_disputes_reporter_id ON disputes(reporter_id);
CREATE INDEX idx_disputes_status ON disputes(status);

CREATE TRIGGER set_updated_at BEFORE UPDATE ON disputes
FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
