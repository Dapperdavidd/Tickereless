ALTER TABLE users DROP CONSTRAINT users_email_password_together;
ALTER TABLE users ADD CONSTRAINT users_password_requires_email CHECK (
    password_hash IS NULL OR email IS NOT NULL
);

CREATE TABLE auth_identities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL CHECK (provider IN ('google')),
    provider_subject TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (provider, provider_subject),
    UNIQUE (user_id, provider)
);
