INSERT INTO company_aliases (company_id, alias, normalized_alias)
SELECT companies.id, aliases.alias, lower(aliases.alias)
FROM companies
JOIN (VALUES
    ('apple', 'Apple Intelligence'), ('apple', 'Apple Pencil'), ('apple', 'HomePod'),
    ('apple', 'iMac'), ('apple', 'Mac mini'), ('apple', 'Mac Studio'), ('apple', 'Mac Pro'),
    ('meta', 'Meta Quest'), ('meta', 'Quest 2'), ('meta', 'Quest 3'), ('meta', 'Quest Pro'),
    ('meta', 'Meta AI'), ('meta', 'Portal'), ('meta', 'Workplace'),
    ('alphabet', 'Google Pixel'), ('alphabet', 'Pixel Watch'), ('alphabet', 'Pixel Buds'),
    ('alphabet', 'Google Play'), ('alphabet', 'Google Drive'), ('alphabet', 'Google Meet'),
    ('alphabet', 'Google Docs'), ('alphabet', 'Google Assistant'), ('alphabet', 'YouTube Music'),
    ('nvidia', 'GeForce RTX'), ('nvidia', 'GeForce GTX'), ('nvidia', 'RTX Studio'),
    ('nvidia', 'NVIDIA Broadcast'), ('nvidia', 'GeForce NOW'), ('nvidia', 'BlueField'),
    ('nvidia', 'Grace Hopper'), ('nvidia', 'NVIDIA DRIVE')
) AS aliases(slug, alias) ON aliases.slug = companies.slug
ON CONFLICT (company_id, normalized_alias) DO NOTHING;
