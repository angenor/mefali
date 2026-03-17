CREATE TABLE kyc_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type kyc_document_type NOT NULL,
    encrypted_path TEXT NOT NULL,
    verified_by UUID REFERENCES users(id),
    status kyc_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_kyc_documents_user_id ON kyc_documents(user_id);
CREATE INDEX idx_kyc_documents_status ON kyc_documents(status);

CREATE TRIGGER set_updated_at BEFORE UPDATE ON kyc_documents
FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
