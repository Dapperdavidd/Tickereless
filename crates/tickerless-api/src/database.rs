use std::collections::HashMap;

use sqlx::{FromRow, PgPool, postgres::PgPoolOptions};

use crate::{
    catalog::CompanyCatalog,
    models::{Company, TokenizedAsset},
};

static MIGRATOR: sqlx::migrate::Migrator = sqlx::migrate!("../../migrations");

#[derive(FromRow)]
struct CompanyRow {
    slug: String,
    name: String,
    ticker: String,
    description: String,
    symbol: Option<String>,
    network: Option<String>,
    environment: Option<String>,
    contract_address: Option<String>,
}

pub async fn connect(database_url: &str) -> Result<PgPool, sqlx::Error> {
    PgPoolOptions::new()
        .max_connections(10)
        .connect(database_url)
        .await
}

pub async fn migrate(pool: &PgPool) -> Result<(), sqlx::migrate::MigrateError> {
    MIGRATOR.run(pool).await
}

pub async fn load_catalog(pool: &PgPool) -> Result<CompanyCatalog, sqlx::Error> {
    let rows = sqlx::query_as::<_, CompanyRow>(
        "SELECT c.slug, c.name, c.ticker, c.description, a.symbol, a.network, \
         a.environment, a.contract_address FROM companies c LEFT JOIN tokenized_assets a \
         ON a.company_id = c.id AND a.active = true AND a.network = 'Base Sepolia' \
         AND a.environment = 'demo' ORDER BY c.name",
    )
    .fetch_all(pool)
    .await?;
    let aliases = sqlx::query_as::<_, (String, String)>(
        "SELECT c.slug, a.alias FROM company_aliases a JOIN companies c ON c.id = a.company_id ORDER BY a.alias",
    ).fetch_all(pool).await?;
    let themes = sqlx::query_as::<_, (String, String)>(
        "SELECT c.slug, t.theme FROM company_themes t JOIN companies c ON c.id = t.company_id ORDER BY t.theme",
    ).fetch_all(pool).await?;

    let mut aliases_by_slug: HashMap<String, Vec<String>> = HashMap::new();
    for (slug, alias) in aliases {
        aliases_by_slug.entry(slug).or_default().push(alias);
    }
    let mut themes_by_slug: HashMap<String, Vec<String>> = HashMap::new();
    for (slug, theme) in themes {
        themes_by_slug.entry(slug).or_default().push(theme);
    }

    let companies = rows
        .into_iter()
        .map(|row| {
            let asset = row.symbol.map(|symbol| TokenizedAsset {
                symbol,
                network: row.network.expect("asset network is non-null"),
                environment: row.environment.expect("asset environment is non-null"),
                contract_address: row.contract_address,
            });
            Company {
                aliases: aliases_by_slug.remove(&row.slug).unwrap_or_default(),
                themes: themes_by_slug.remove(&row.slug).unwrap_or_default(),
                slug: row.slug,
                name: row.name,
                ticker: row.ticker,
                description: row.description,
                asset,
            }
        })
        .collect();
    Ok(CompanyCatalog::new(companies))
}
