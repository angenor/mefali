CREATE TABLE sponsorships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sponsor_id UUID NOT NULL REFERENCES users(id),
    sponsored_id UUID NOT NULL UNIQUE REFERENCES users(id),
    status sponsorship_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (sponsor_id != sponsored_id)
);

CREATE INDEX idx_sponsorships_sponsor_id ON sponsorships(sponsor_id);

CREATE TRIGGER set_updated_at BEFORE UPDATE ON sponsorships
FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
