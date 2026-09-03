CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    ticker TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE company_aliases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    alias TEXT NOT NULL,
    normalized_alias TEXT NOT NULL,
    UNIQUE (company_id, normalized_alias)
);
CREATE INDEX company_aliases_normalized_idx ON company_aliases (normalized_alias);

CREATE TABLE company_themes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    theme TEXT NOT NULL,
    normalized_theme TEXT NOT NULL,
    UNIQUE (company_id, normalized_theme)
);
CREATE INDEX company_themes_normalized_idx ON company_themes (normalized_theme);

CREATE TABLE tokenized_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    network TEXT NOT NULL,
    environment TEXT NOT NULL CHECK (environment IN ('demo', 'testnet', 'mainnet')),
    contract_address TEXT,
    decimals SMALLINT NOT NULL DEFAULT 18 CHECK (decimals BETWEEN 0 AND 36),
    active BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (symbol, network, environment),
    UNIQUE (company_id, network, environment)
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_address TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE discoveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
    method TEXT NOT NULL CHECK (method IN ('search', 'lens', 'link')),
    source TEXT NOT NULL,
    explanation TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX discoveries_user_created_idx ON discoveries (user_id, created_at DESC);

CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE RESTRICT,
    discovery_id UUID REFERENCES discoveries(id) ON DELETE SET NULL,
    asset_id UUID NOT NULL REFERENCES tokenized_assets(id) ON DELETE RESTRICT,
    tx_hash TEXT UNIQUE,
    amount_usdc NUMERIC(30, 6) NOT NULL CHECK (amount_usdc > 0),
    token_amount NUMERIC(38, 18) CHECK (token_amount >= 0),
    status TEXT NOT NULL CHECK (status IN ('pending', 'confirmed', 'failed')),
    network TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    confirmed_at TIMESTAMPTZ
);
CREATE INDEX transactions_user_created_idx ON transactions (user_id, created_at DESC);
