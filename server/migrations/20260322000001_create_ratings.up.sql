-- Ratings table: double rating (merchant + driver) per order
CREATE TABLE ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id),
    rater_id UUID NOT NULL REFERENCES users(id),
    rated_type TEXT NOT NULL CHECK (rated_type IN ('merchant', 'driver')),
    rated_id UUID NOT NULL REFERENCES users(id),
    score SMALLINT NOT NULL CHECK (score >= 1 AND score <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (order_id, rated_type)
);

CREATE INDEX idx_ratings_rated_id_type ON ratings (rated_id, rated_type);
CREATE INDEX idx_ratings_order_id ON ratings (order_id);
