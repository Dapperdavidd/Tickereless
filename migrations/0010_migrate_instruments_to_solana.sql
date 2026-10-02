ALTER TABLE tokenized_assets
    DROP CONSTRAINT tokenized_assets_contract_address_shape,
    DROP CONSTRAINT tokenized_assets_market_address_shape,
    DROP CONSTRAINT tokenized_assets_payment_address_shape,
    DROP CONSTRAINT tokenized_assets_execution_metadata_complete;

ALTER TABLE tokenized_assets
    ADD COLUMN provider TEXT,
    ADD COLUMN issuer_url TEXT,
    ADD COLUMN trading_halted BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN supports_atomic_swaps BOOLEAN NOT NULL DEFAULT false;

UPDATE tokenized_assets SET active = false WHERE network = 'Base Sepolia';

INSERT INTO companies (slug, name, ticker, description) VALUES
    ('amazon', 'Amazon', 'AMZN', 'Commerce and cloud-computing company behind Amazon and AWS.'),
    ('tesla', 'Tesla', 'TSLA', 'Electric vehicle, energy storage, and charging company.')
ON CONFLICT (slug) DO UPDATE SET
    name = EXCLUDED.name,
    ticker = EXCLUDED.ticker,
    description = EXCLUDED.description,
    updated_at = now();

INSERT INTO company_aliases (company_id, alias, normalized_alias)
SELECT companies.id, aliases.alias, lower(aliases.alias)
FROM companies
JOIN (VALUES
    ('amazon', 'Amazon'), ('amazon', 'AWS'), ('amazon', 'Prime'),
    ('amazon', 'Alexa'), ('amazon', 'Kindle'), ('amazon', 'Audible'),
    ('tesla', 'Tesla'), ('tesla', 'Model 3'), ('tesla', 'Model Y'),
    ('tesla', 'Cybertruck'), ('tesla', 'Supercharger'), ('tesla', 'Powerwall')
) AS aliases(slug, alias) ON aliases.slug = companies.slug
ON CONFLICT (company_id, normalized_alias) DO UPDATE SET alias = EXCLUDED.alias;

INSERT INTO company_themes (company_id, theme, normalized_theme)
SELECT companies.id, themes.theme, lower(themes.theme)
FROM companies
JOIN (VALUES
    ('amazon', 'ecommerce'), ('amazon', 'cloud computing'),
    ('tesla', 'electric vehicles'), ('tesla', 'energy storage')
) AS themes(slug, theme) ON themes.slug = companies.slug
ON CONFLICT (company_id, normalized_theme) DO UPDATE SET theme = EXCLUDED.theme;

INSERT INTO tokenized_assets (
    company_id, symbol, network, environment, contract_address, decimals,
    price_usdc, payment_token_address, explorer_url, provider, issuer_url,
    supports_atomic_swaps
)
SELECT companies.id, instruments.symbol, 'Solana', 'mainnet', instruments.mint,
    8, instruments.price, 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
    'https://explorer.solana.com/address/' || instruments.mint,
    'xStocks', 'https://xstocks.com', true
FROM companies
JOIN (VALUES
    ('apple', 'AAPLx', 'XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp', 331.460000::NUMERIC),
    ('nvidia', 'NVDAx', 'Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh', 232.885000::NUMERIC),
    ('meta', 'METAx', 'Xsa62P5mvPszXL1krVUnU5ar38bBSVcWAB6fmPCo5Zu', 730.375000::NUMERIC),
    ('alphabet', 'GOOGLx', 'XsCPL9dNWBMvFtTmwcCA5v3xWPSMEBCszbQdiLLq6aN', 341.115000::NUMERIC),
    ('microsoft', 'MSFTx', 'XspzcW1PRtgf6Wj92HCiZdjzKCyFekVD8P5Ueh3dRMX', 516.890000::NUMERIC),
    ('amazon', 'AMZNx', 'Xs3eBt7uRfJX8QUs4suhyU8p2M6DoUDrJyWBa8LLZsg', 249.751000::NUMERIC),
    ('tesla', 'TSLAx', 'XsDoVfqeBukxuZHWhdvWHBhgEHjGNst4MLodqsJHzoB', 357.780000::NUMERIC)
) AS instruments(slug, symbol, mint, price) ON instruments.slug = companies.slug
ON CONFLICT (symbol, network, environment) DO UPDATE SET
    company_id = EXCLUDED.company_id,
    contract_address = EXCLUDED.contract_address,
    decimals = EXCLUDED.decimals,
    price_usdc = EXCLUDED.price_usdc,
    payment_token_address = EXCLUDED.payment_token_address,
    explorer_url = EXCLUDED.explorer_url,
    provider = EXCLUDED.provider,
    issuer_url = EXCLUDED.issuer_url,
    supports_atomic_swaps = EXCLUDED.supports_atomic_swaps,
    active = true;
