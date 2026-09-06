use std::collections::HashMap;

use sqlx::{FromRow, PgPool, postgres::PgPoolOptions};

use crate::{
    auth,
    catalog::CompanyCatalog,
    chain::VerifiedPurchase,
    models::{
        AuthUser, Company, CreateDiscoveryRequest, Discovery, SubmitTransactionRequest,
        TokenizedAsset, TransactionRecord, WorldDiscoveryContext, WorldPosition, WorldSummary,
    },
};

#[derive(Debug)]
pub enum RegisterUserError {
    EmailExists,
    Database(sqlx::Error),
}

pub async fn register_email_user(
    pool: &PgPool,
    email: &str,
    password_hash: &str,
) -> Result<AuthUser, RegisterUserError> {
    sqlx::query_as::<_, AuthUser>(
        "INSERT INTO users (email, password_hash) VALUES ($1, $2) \
         RETURNING id, email, wallet_address",
    )
    .bind(email)
    .bind(password_hash)
    .fetch_one(pool)
    .await
    .map_err(|error| {
        if error
            .as_database_error()
            .and_then(|value| value.constraint())
            == Some("users_email_unique_idx")
        {
            RegisterUserError::EmailExists
        } else {
            RegisterUserError::Database(error)
        }
    })
}

pub async fn email_user_credentials(
    pool: &PgPool,
    email: &str,
) -> Result<Option<(AuthUser, String)>, sqlx::Error> {
    sqlx::query_as::<_, (uuid::Uuid, String, Option<String>, String)>(
        "SELECT id, email, wallet_address, password_hash FROM users \
         WHERE lower(email) = lower($1) AND password_hash IS NOT NULL",
    )
    .bind(email)
    .fetch_optional(pool)
    .await
    .map(|row| {
        row.map(|(id, email, wallet_address, password_hash)| {
            (
                AuthUser {
                    id,
                    email,
                    wallet_address,
                },
                password_hash,
            )
        })
    })
}

pub async fn create_session(
    pool: &PgPool,
    user_id: uuid::Uuid,
    token_hash: &[u8],
) -> Result<(), sqlx::Error> {
    sqlx::query(
        "INSERT INTO auth_sessions (user_id, token_hash, expires_at) \
         VALUES ($1, $2, now() + make_interval(days => $3::int))",
    )
    .bind(user_id)
    .bind(token_hash)
    .bind(auth::SESSION_TTL_DAYS as i32)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn authenticated_user(
    pool: &PgPool,
    token_hash: &[u8],
) -> Result<Option<AuthUser>, sqlx::Error> {
    let mut transaction = pool.begin().await?;
    let user = sqlx::query_as::<_, AuthUser>(
        "SELECT u.id, u.email, u.wallet_address FROM auth_sessions s \
         JOIN users u ON u.id = s.user_id WHERE s.token_hash = $1 \
         AND s.revoked_at IS NULL AND s.expires_at > now() AND u.email IS NOT NULL",
    )
    .bind(token_hash)
    .fetch_optional(&mut *transaction)
    .await?;
    if user.is_some() {
        sqlx::query("UPDATE auth_sessions SET last_used_at = now() WHERE token_hash = $1")
            .bind(token_hash)
            .execute(&mut *transaction)
            .await?;
    }
    transaction.commit().await?;
    Ok(user)
}

pub async fn revoke_session(pool: &PgPool, token_hash: &[u8]) -> Result<bool, sqlx::Error> {
    Ok(sqlx::query(
        "UPDATE auth_sessions SET revoked_at = now() WHERE token_hash = $1 \
         AND revoked_at IS NULL AND expires_at > now()",
    )
    .bind(token_hash)
    .execute(pool)
    .await?
    .rows_affected()
        == 1)
}

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
    payment_token_address: Option<String>,
    chain_id: Option<i64>,
    explorer_url: Option<String>,
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
         a.environment, a.contract_address, a.market_address, a.price_usdc, \
         a.payment_token_address, a.chain_id, a.explorer_url \
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
                payment_token_address: row.payment_token_address,
                chain_id: row.chain_id,
                explorer_url: row.explorer_url,
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

#[derive(Debug)]
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

    let (id, created_at) = sqlx::query_as::<_, (uuid::Uuid, chrono::DateTime<chrono::Utc>)>(
        "INSERT INTO discoveries (user_id, company_id, method, source, explanation) \
             VALUES ($1, $2, $3, $4, $5) RETURNING id, created_at",
    )
    .bind(Option::<uuid::Uuid>::None)
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

pub struct DeploymentRegistration {
    pub market_address: String,
    pub payment_token_address: String,
    pub chain_id: i64,
    pub explorer_url: String,
    pub assets: Vec<(String, String)>,
}

pub async fn register_deployment(
    pool: &PgPool,
    registration: &DeploymentRegistration,
) -> Result<(), sqlx::Error> {
    let mut transaction = pool.begin().await?;
    for (symbol, contract_address) in &registration.assets {
        let result = sqlx::query(
            "UPDATE tokenized_assets SET contract_address = $1, market_address = $2, \
             payment_token_address = $3, chain_id = $4, explorer_url = $5 \
             WHERE symbol = $6 AND network = 'Base Sepolia' AND environment = 'demo'",
        )
        .bind(contract_address)
        .bind(&registration.market_address)
        .bind(&registration.payment_token_address)
        .bind(registration.chain_id)
        .bind(&registration.explorer_url)
        .bind(symbol)
        .execute(&mut *transaction)
        .await?;
        if result.rows_affected() != 1 {
            return Err(sqlx::Error::RowNotFound);
        }
    }
    transaction.commit().await
}

#[derive(Debug)]
pub enum RecordTransactionError {
    DiscoveryMismatch,
    Duplicate,
    Database(sqlx::Error),
}

pub async fn record_transaction(
    pool: &PgPool,
    input: &SubmitTransactionRequest,
    purchase: &VerifiedPurchase,
) -> Result<TransactionRecord, RecordTransactionError> {
    let mut transaction = pool
        .begin()
        .await
        .map_err(RecordTransactionError::Database)?;
    let company = sqlx::query_as::<_, (uuid::Uuid, String, String, uuid::Uuid, String, String)>(
        "SELECT c.id, c.name, c.ticker, a.id, a.symbol, a.network FROM companies c \
         JOIN tokenized_assets a ON a.company_id = c.id AND a.active = true \
         WHERE c.slug = $1 AND a.network = 'Base Sepolia' AND a.environment = 'demo'",
    )
    .bind(&input.company_slug)
    .fetch_one(&mut *transaction)
    .await
    .map_err(RecordTransactionError::Database)?;
    let user_id = sqlx::query_scalar::<_, uuid::Uuid>(
        "INSERT INTO users (wallet_address) VALUES ($1) \
         ON CONFLICT (wallet_address) DO UPDATE SET wallet_address = EXCLUDED.wallet_address \
         RETURNING id",
    )
    .bind(&input.wallet_address)
    .fetch_one(&mut *transaction)
    .await
    .map_err(RecordTransactionError::Database)?;

    if let Some(discovery_id) = input.discovery_id {
        let linked = sqlx::query(
            "UPDATE discoveries SET user_id = $1 WHERE id = $2 AND company_id = $3 \
             AND (user_id IS NULL OR user_id = $1)",
        )
        .bind(user_id)
        .bind(discovery_id)
        .bind(company.0)
        .execute(&mut *transaction)
        .await
        .map_err(RecordTransactionError::Database)?;
        if linked.rows_affected() != 1 {
            return Err(RecordTransactionError::DiscoveryMismatch);
        }
    }

    let inserted = sqlx::query_as::<
        _,
        (
            uuid::Uuid,
            chrono::DateTime<chrono::Utc>,
            chrono::DateTime<chrono::Utc>,
        ),
    >(
        "INSERT INTO transactions (user_id, company_id, discovery_id, asset_id, tx_hash, \
         amount_usdc, token_amount, status, network, confirmed_at) \
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'confirmed', $8, now()) \
         RETURNING id, created_at, confirmed_at",
    )
    .bind(user_id)
    .bind(company.0)
    .bind(input.discovery_id)
    .bind(company.3)
    .bind(&input.tx_hash)
    .bind(purchase.amount_usdc)
    .bind(purchase.token_amount)
    .bind(&company.5)
    .fetch_one(&mut *transaction)
    .await
    .map_err(|error| {
        if error
            .as_database_error()
            .and_then(|value| value.constraint())
            == Some("transactions_tx_hash_key")
        {
            RecordTransactionError::Duplicate
        } else {
            RecordTransactionError::Database(error)
        }
    })?;
    transaction
        .commit()
        .await
        .map_err(RecordTransactionError::Database)?;

    Ok(TransactionRecord {
        id: inserted.0,
        company_slug: input.company_slug.clone(),
        company_name: company.1,
        ticker: company.2,
        asset_symbol: company.4,
        tx_hash: input.tx_hash.clone(),
        amount_usdc: purchase.amount_usdc,
        token_amount: purchase.token_amount,
        status: "confirmed".to_owned(),
        network: company.5,
        created_at: inserted.1,
        confirmed_at: Some(inserted.2),
    })
}

#[derive(FromRow)]
struct WorldPositionRow {
    company_slug: String,
    company_name: String,
    ticker: String,
    asset_symbol: String,
    invested_usdc: rust_decimal::Decimal,
    token_amount: rust_decimal::Decimal,
}

pub async fn world(pool: &PgPool, wallet_address: &str) -> Result<WorldSummary, sqlx::Error> {
    let rows = sqlx::query_as::<_, WorldPositionRow>(
        "SELECT c.slug AS company_slug, c.name AS company_name, c.ticker, \
         a.symbol AS asset_symbol, SUM(t.amount_usdc)::NUMERIC AS invested_usdc, \
         SUM(t.token_amount)::NUMERIC AS token_amount FROM transactions t \
         JOIN users u ON u.id = t.user_id JOIN companies c ON c.id = t.company_id \
         JOIN tokenized_assets a ON a.id = t.asset_id \
         WHERE u.wallet_address = $1 AND t.status = 'confirmed' \
         GROUP BY c.slug, c.name, c.ticker, a.symbol ORDER BY SUM(t.amount_usdc) DESC",
    )
    .bind(wallet_address.to_ascii_lowercase())
    .fetch_all(pool)
    .await?;
    let contexts = sqlx::query_as::<_, (String, String, String)>(
        "SELECT c.slug, d.method, d.source FROM discoveries d \
         JOIN users u ON u.id = d.user_id JOIN companies c ON c.id = d.company_id \
         WHERE u.wallet_address = $1 ORDER BY d.created_at DESC",
    )
    .bind(wallet_address.to_ascii_lowercase())
    .fetch_all(pool)
    .await?;
    let discovery_count = contexts.len();
    let mut contexts_by_company: HashMap<String, Vec<WorldDiscoveryContext>> = HashMap::new();
    for (slug, method, source) in contexts {
        contexts_by_company
            .entry(slug)
            .or_default()
            .push(WorldDiscoveryContext { method, source });
    }
    let companies: Vec<_> = rows
        .into_iter()
        .map(|row| WorldPosition {
            discoveries: contexts_by_company
                .remove(&row.company_slug)
                .unwrap_or_default(),
            company_slug: row.company_slug,
            company_name: row.company_name,
            ticker: row.ticker,
            asset_symbol: row.asset_symbol,
            invested_usdc: row.invested_usdc,
            token_amount: row.token_amount,
        })
        .collect();
    let total_owned_usdc = companies.iter().map(|company| company.invested_usdc).sum();
    Ok(WorldSummary {
        total_owned_usdc,
        company_count: companies.len(),
        discovery_count,
        companies,
    })
}

#[cfg(test)]
mod tests {
    use rust_decimal::Decimal;
    use sqlx::PgPool;
    use uuid::Uuid;

    use super::{
        MIGRATOR, authenticated_user, create_discovery, create_session, discovery_history,
        email_user_credentials, load_catalog, record_transaction, register_email_user,
        revoke_session, world,
    };
    use crate::{
        chain::VerifiedPurchase,
        models::{CreateDiscoveryRequest, DiscoveryMethod, SubmitTransactionRequest},
    };

    const WALLET: &str = "0x0000000000000000000000000000000000000001";

    #[sqlx::test(migrator = "MIGRATOR")]
    async fn migrations_seed_the_resolvable_catalog(pool: PgPool) {
        let catalog = load_catalog(&pool).await.expect("catalog should load");
        let meta = catalog
            .find_by_slug("meta")
            .expect("seeded Meta company should exist");
        assert_eq!(meta.ticker, "META");
        assert_eq!(
            meta.asset.as_ref().map(|asset| asset.symbol.as_str()),
            Some("tMETAc")
        );
    }

    #[sqlx::test(migrator = "MIGRATOR")]
    async fn verified_purchase_claims_discovery_and_builds_world(pool: PgPool) {
        let discovery = create_discovery(
            &pool,
            &CreateDiscoveryRequest {
                company_slug: "nvidia".to_owned(),
                method: DiscoveryMethod::Lens,
                source: "GeForce RTX".to_owned(),
                explanation: "GeForce is an NVIDIA product family.".to_owned(),
            },
        )
        .await
        .expect("discovery should be created");
        let initial_user =
            sqlx::query_scalar::<_, Option<Uuid>>("SELECT user_id FROM discoveries WHERE id = $1")
                .bind(discovery.id)
                .fetch_one(&pool)
                .await
                .expect("discovery should exist");
        assert!(initial_user.is_none());

        let input = SubmitTransactionRequest {
            wallet_address: WALLET.to_owned(),
            company_slug: "nvidia".to_owned(),
            discovery_id: Some(discovery.id),
            tx_hash: format!("0x{}", "1".repeat(64)),
        };
        record_transaction(
            &pool,
            &input,
            &VerifiedPurchase {
                amount_usdc: Decimal::new(9_000_000, 6),
                token_amount: Decimal::new(5, 2),
            },
        )
        .await
        .expect("verified purchase should be recorded");

        let history = discovery_history(&pool, WALLET, 50)
            .await
            .expect("history should load");
        assert_eq!(history.len(), 1);
        assert_eq!(history[0].id, discovery.id);

        let summary = world(&pool, WALLET).await.expect("world should load");
        assert_eq!(summary.total_owned_usdc, Decimal::new(9, 0));
        assert_eq!(summary.company_count, 1);
        assert_eq!(summary.discovery_count, 1);
        assert_eq!(summary.companies[0].token_amount, Decimal::new(5, 2));
        assert_eq!(summary.companies[0].discoveries[0].method, "lens");
    }

    #[sqlx::test(migrator = "MIGRATOR")]
    async fn email_account_session_lifecycle(pool: PgPool) {
        let password_hash = crate::auth::hash_password("a secure demo password");
        let user = register_email_user(&pool, "owner@example.com", &password_hash)
            .await
            .expect("user should register");
        assert_eq!(user.email, "owner@example.com");
        assert!(user.wallet_address.is_none());

        let (_, stored_hash) = email_user_credentials(&pool, "OWNER@example.com")
            .await
            .expect("lookup should work")
            .expect("account should exist");
        assert!(crate::auth::verify_password(
            "a secure demo password",
            &stored_hash
        ));

        let (_, token_hash) = crate::auth::new_session_token();
        create_session(&pool, user.id, &token_hash)
            .await
            .expect("session should be created");
        assert!(
            authenticated_user(&pool, &token_hash)
                .await
                .expect("session lookup should work")
                .is_some()
        );
        assert!(
            revoke_session(&pool, &token_hash)
                .await
                .expect("session should revoke")
        );
        assert!(
            authenticated_user(&pool, &token_hash)
                .await
                .expect("revoked lookup should work")
                .is_none()
        );
    }
}
