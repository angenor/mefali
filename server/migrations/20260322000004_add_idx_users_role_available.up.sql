-- Composite index for efficient admin dashboard count_drivers_online() query
CREATE INDEX idx_users_role_available ON users(role, is_available);
