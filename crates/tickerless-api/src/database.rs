use std::collections::HashMap;

use sqlx::{FromRow, PgPool, postgres::PgPoolOptions};

use crate::{
    catalog::CompanyCatalog,
    models::{Company, CreateDiscoveryRequest, Discovery, TokenizedAsset},
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
    market_address: Option<String>,
    price_usdc: Option<rust_decimal::Decimal>,
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
         a.environment, a.contract_address, a.market_address, a.price_usdc \
         FROM companies c LEFT JOIN tokenized_assets a \
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
                market_address: row.market_address,
                price_usdc: row.price_usdc.expect("asset price is non-null"),
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

pub enum CreateDiscoveryError {
    CompanyNotFound,
    Database(sqlx::Error),
}

impl From<sqlx::Error> for CreateDiscoveryError {
    fn from(error: sqlx::Error) -> Self {
        Self::Database(error)
    }
}

pub async fn create_discovery(
    pool: &PgPool,
    input: &CreateDiscoveryRequest,
) -> Result<Discovery, CreateDiscoveryError> {
    let mut transaction = pool.begin().await?;
    let company = sqlx::query_as::<_, (uuid::Uuid, String, String)>(
        "SELECT id, name, ticker FROM companies WHERE slug = $1",
    )
    .bind(&input.company_slug)
    .fetch_optional(&mut *transaction)
    .await?
    .ok_or(CreateDiscoveryError::CompanyNotFound)?;

    let user_id = if let Some(wallet) = input.wallet_address.as_deref() {
        Some(
            sqlx::query_scalar::<_, uuid::Uuid>(
                "INSERT INTO users (wallet_address) VALUES ($1) \
                 ON CONFLICT (wallet_address) DO UPDATE SET wallet_address = EXCLUDED.wallet_address \
                 RETURNING id",
            )
            .bind(wallet.to_ascii_lowercase())
            .fetch_one(&mut *transaction)
            .await?,
        )
    } else {
        None
    };

    let (id, created_at) = sqlx::query_as::<_, (uuid::Uuid, chrono::DateTime<chrono::Utc>)>(
        "INSERT INTO discoveries (user_id, company_id, method, source, explanation) \
             VALUES ($1, $2, $3, $4, $5) RETURNING id, created_at",
    )
    .bind(user_id)
    .bind(company.0)
    .bind(input.method.as_str())
    .bind(input.source.trim())
    .bind(input.explanation.trim())
    .fetch_one(&mut *transaction)
    .await?;
    transaction.commit().await?;

    Ok(Discovery {
        id,
        company_slug: input.company_slug.clone(),
        company_name: company.1,
        ticker: company.2,
        method: input.method.as_str().to_owned(),
        source: input.source.trim().to_owned(),
        explanation: input.explanation.trim().to_owned(),
        created_at,
    })
}

pub async fn discovery_history(
    pool: &PgPool,
    wallet_address: &str,
    limit: i64,
) -> Result<Vec<Discovery>, sqlx::Error> {
    sqlx::query_as::<_, Discovery>(
        "SELECT d.id, c.slug AS company_slug, c.name AS company_name, c.ticker, \
         d.method, d.source, d.explanation, d.created_at FROM discoveries d \
         JOIN companies c ON c.id = d.company_id JOIN users u ON u.id = d.user_id \
         WHERE u.wallet_address = $1 ORDER BY d.created_at DESC LIMIT $2",
    )
    .bind(wallet_address.to_ascii_lowercase())
    .bind(limit)
    .fetch_all(pool)
    .await
}
