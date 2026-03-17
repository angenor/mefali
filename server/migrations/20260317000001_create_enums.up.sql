-- Migration 001: PostgreSQL enums + utility function
-- Maps to Rust domain enums in server/crates/domain/src/*/model.rs

CREATE TYPE user_role AS ENUM ('client', 'merchant', 'driver', 'agent', 'admin');
CREATE TYPE user_status AS ENUM ('active', 'pending_kyc', 'suspended', 'deactivated');
CREATE TYPE vendor_status AS ENUM ('open', 'overwhelmed', 'auto_paused', 'closed');
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'collected', 'in_transit', 'delivered', 'cancelled');
CREATE TYPE payment_type AS ENUM ('cod', 'mobile_money');
CREATE TYPE payment_status AS ENUM ('pending', 'escrow_held', 'released', 'refunded');
CREATE TYPE delivery_status AS ENUM ('pending', 'assigned', 'picked_up', 'in_transit', 'delivered', 'failed', 'client_absent');
CREATE TYPE wallet_transaction_type AS ENUM ('credit', 'debit', 'withdrawal', 'refund');
CREATE TYPE dispute_type AS ENUM ('incomplete', 'quality', 'wrong_order', 'other');
CREATE TYPE dispute_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');
CREATE TYPE sponsorship_status AS ENUM ('active', 'suspended', 'terminated');
CREATE TYPE kyc_document_type AS ENUM ('cni', 'permis');
CREATE TYPE kyc_status AS ENUM ('pending', 'verified', 'rejected');

-- Utility: auto-update updated_at on row modification
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
