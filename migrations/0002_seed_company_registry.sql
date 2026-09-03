INSERT INTO companies (slug, name, ticker, description) VALUES
    ('apple', 'Apple', 'AAPL', 'Consumer technology company behind iPhone, Mac, and other devices.'),
    ('meta', 'Meta Platforms', 'META', 'Technology company behind Instagram, WhatsApp, Facebook, and Threads.'),
    ('alphabet', 'Alphabet', 'GOOGL', 'Technology company behind Google, YouTube, Android, and Google Cloud.'),
    ('nvidia', 'NVIDIA', 'NVDA', 'Computing company known for GPUs and accelerated AI infrastructure.');

INSERT INTO company_aliases (company_id, alias, normalized_alias)
SELECT companies.id, aliases.alias, lower(aliases.alias)
FROM companies
JOIN (VALUES
    ('apple', 'iPhone'), ('apple', 'Mac'), ('apple', 'MacBook'), ('apple', 'iPad'),
    ('apple', 'AirPods'), ('apple', 'Apple Watch'), ('apple', 'Vision Pro'),
    ('meta', 'Meta'), ('meta', 'Instagram'), ('meta', 'WhatsApp'), ('meta', 'Facebook'),
    ('meta', 'Threads'), ('meta', 'Quest'),
    ('alphabet', 'Google'), ('alphabet', 'YouTube'), ('alphabet', 'Gemini'),
    ('alphabet', 'Android'), ('alphabet', 'Chrome'), ('alphabet', 'Google Cloud'), ('alphabet', 'Waymo'),
    ('nvidia', 'GeForce'), ('nvidia', 'RTX'), ('nvidia', 'CUDA'), ('nvidia', 'DGX')
) AS aliases(slug, alias) ON aliases.slug = companies.slug;

INSERT INTO company_themes (company_id, theme, normalized_theme)
SELECT companies.id, themes.theme, lower(themes.theme)
FROM companies
JOIN (VALUES
    ('apple', 'consumer technology'), ('apple', 'smartphones'), ('apple', 'personal computing'),
    ('meta', 'social media'), ('meta', 'virtual reality'), ('meta', 'artificial intelligence'),
    ('alphabet', 'search engines'), ('alphabet', 'cloud computing'), ('alphabet', 'artificial intelligence'),
    ('nvidia', 'AI chips'), ('nvidia', 'GPU infrastructure'), ('nvidia', 'artificial intelligence')
) AS themes(slug, theme) ON themes.slug = companies.slug;

INSERT INTO tokenized_assets (company_id, symbol, network, environment)
SELECT id, 't' || ticker || 'c', 'Base Sepolia', 'demo' FROM companies;
