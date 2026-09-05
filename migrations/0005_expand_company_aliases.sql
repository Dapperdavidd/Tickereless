INSERT INTO company_aliases (company_id, alias, normalized_alias)
SELECT companies.id, aliases.alias, lower(aliases.alias)
FROM companies
JOIN (VALUES
    ('apple', 'Apple'), ('apple', 'iOS'), ('apple', 'App Store'), ('apple', 'Safari'),
    ('apple', 'Beats'), ('apple', 'Apple TV'), ('apple', 'Apple Music'),
    ('meta', 'Messenger'), ('meta', 'Oculus'), ('meta', 'Horizon'), ('meta', 'Ray-Ban Meta'),
    ('alphabet', 'Gmail'), ('alphabet', 'Google Maps'), ('alphabet', 'Pixel'),
    ('alphabet', 'Google Photos'), ('alphabet', 'Nest'), ('alphabet', 'Chromebook'),
    ('nvidia', 'NVIDIA'), ('nvidia', 'Omniverse'), ('nvidia', 'TensorRT'),
    ('nvidia', 'NVIDIA Shield'), ('nvidia', 'Jetson'), ('nvidia', 'G-SYNC')
) AS aliases(slug, alias) ON aliases.slug = companies.slug
ON CONFLICT (company_id, normalized_alias) DO NOTHING;
