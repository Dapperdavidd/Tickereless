ALTER TABLE users ALTER COLUMN wallet_address DROP NOT NULL;

ALTER TABLE users
    ADD COLUMN email TEXT,
    ADD COLUMN password_hash TEXT,
    ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ADD CONSTRAINT users_identity_present CHECK (wallet_address IS NOT NULL OR email IS NOT NULL),
    ADD CONSTRAINT users_email_password_together CHECK (
        (email IS NULL AND password_hash IS NULL) OR
        (email IS NOT NULL AND password_hash IS NOT NULL)
    );

CREATE UNIQUE INDEX users_email_unique_idx ON users (lower(email)) WHERE email IS NOT NULL;

CREATE TABLE auth_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash BYTEA NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_used_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at TIMESTAMPTZ
);

CREATE INDEX auth_sessions_user_idx ON auth_sessions (user_id, created_at DESC);
CREATE INDEX auth_sessions_expiry_idx ON auth_sessions (expires_at) WHERE revoked_at IS NULL;
