ALTER TABLE tokenized_assets
    ADD COLUMN price_usdc NUMERIC(30, 6),
    ADD COLUMN market_address TEXT;

ALTER TABLE tokenized_assets
    ADD CONSTRAINT tokenized_assets_positive_price CHECK (price_usdc > 0),
    ADD CONSTRAINT tokenized_assets_contract_address_shape CHECK (
        contract_address IS NULL OR contract_address ~ '^0x[0-9a-fA-F]{40}$'
    ),
    ADD CONSTRAINT tokenized_assets_market_address_shape CHECK (
        market_address IS NULL OR market_address ~ '^0x[0-9a-fA-F]{40}$'
    );

UPDATE tokenized_assets AS assets
SET price_usdc = prices.price
FROM companies
JOIN (VALUES
    ('apple', 200.000000::NUMERIC),
    ('nvidia', 180.000000::NUMERIC),
    ('meta', 500.000000::NUMERIC),
    ('alphabet', 150.000000::NUMERIC)
) AS prices(slug, price) ON prices.slug = companies.slug
WHERE assets.company_id = companies.id;

ALTER TABLE tokenized_assets ALTER COLUMN price_usdc SET NOT NULL;
