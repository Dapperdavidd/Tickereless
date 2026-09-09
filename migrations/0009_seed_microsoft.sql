INSERT INTO companies (slug, name, ticker, description)
VALUES (
    'microsoft',
    'Microsoft',
    'MSFT',
    'Technology company behind Windows, Surface, Xbox, Azure, and Copilot.'
)
ON CONFLICT (slug) DO UPDATE SET
    name = EXCLUDED.name,
    ticker = EXCLUDED.ticker,
    description = EXCLUDED.description,
    updated_at = now();

INSERT INTO company_aliases (company_id, alias, normalized_alias)
SELECT companies.id, aliases.alias, lower(aliases.alias)
FROM companies
JOIN (VALUES
    ('microsoft', 'Windows'),
    ('microsoft', 'Surface'),
    ('microsoft', 'Surface Laptop'),
    ('microsoft', 'Surface Pro'),
    ('microsoft', 'Xbox'),
    ('microsoft', 'Azure'),
    ('microsoft', 'Copilot'),
    ('microsoft', 'Microsoft 365'),
    ('microsoft', 'Office'),
    ('microsoft', 'Teams')
) AS aliases(slug, alias) ON aliases.slug = companies.slug
ON CONFLICT (company_id, normalized_alias) DO UPDATE SET alias = EXCLUDED.alias;

INSERT INTO company_themes (company_id, theme, normalized_theme)
SELECT companies.id, themes.theme, lower(themes.theme)
FROM companies
JOIN (VALUES
    ('microsoft', 'personal computing'),
    ('microsoft', 'cloud computing'),
    ('microsoft', 'gaming')
) AS themes(slug, theme) ON themes.slug = companies.slug
ON CONFLICT (company_id, normalized_theme) DO UPDATE SET theme = EXCLUDED.theme;

INSERT INTO tokenized_assets (
    company_id,
    symbol,
    network,
    environment,
    price_usdc
)
SELECT id, 'tMSFTc', 'Base Sepolia', 'demo', 430.200000
FROM companies
WHERE slug = 'microsoft'
ON CONFLICT (symbol, network, environment) DO UPDATE SET
    company_id = EXCLUDED.company_id,
    price_usdc = EXCLUDED.price_usdc,
    active = true;
