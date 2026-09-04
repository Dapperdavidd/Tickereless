ALTER TABLE tokenized_assets
    ADD COLUMN payment_token_address TEXT,
    ADD COLUMN chain_id BIGINT,
    ADD COLUMN explorer_url TEXT;

ALTER TABLE tokenized_assets
    ADD CONSTRAINT tokenized_assets_payment_address_shape CHECK (
        payment_token_address IS NULL OR payment_token_address ~ '^0x[0-9a-fA-F]{40}$'
    ),
    ADD CONSTRAINT tokenized_assets_positive_chain_id CHECK (chain_id IS NULL OR chain_id > 0),
    ADD CONSTRAINT tokenized_assets_execution_metadata_complete CHECK (
        (contract_address IS NULL AND market_address IS NULL AND payment_token_address IS NULL
            AND chain_id IS NULL AND explorer_url IS NULL)
        OR
        (contract_address IS NOT NULL AND market_address IS NOT NULL
            AND payment_token_address IS NOT NULL AND chain_id IS NOT NULL
            AND explorer_url IS NOT NULL)
    );
