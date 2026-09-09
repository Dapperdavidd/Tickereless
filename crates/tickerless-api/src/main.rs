use std::{env, io};

use actix_web::{App, HttpServer};
use tickerless_api::{
    AppState,
    chain::ChainClient,
    configure_app,
    database::{self, DeploymentRegistration},
    google::GoogleVerifier,
};
use tracing::info;
use tracing_subscriber::EnvFilter;

const DEFAULT_HOST: &str = "127.0.0.1";
const DEFAULT_PORT: u16 = 8080;

#[actix_web::main]
async fn main() -> io::Result<()> {
    dotenvy::dotenv().ok();

    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| EnvFilter::new("tickerless_api=info,actix_web=info")),
        )
        .init();

    let host = env::var("TICKERLESS_API_HOST").unwrap_or_else(|_| DEFAULT_HOST.to_owned());
    let port = env::var("PORT")
        .or_else(|_| env::var("TICKERLESS_API_PORT"))
        .ok()
        .and_then(|value| value.parse().ok())
        .unwrap_or(DEFAULT_PORT);

    let database_url = env::var("DATABASE_URL")
        .map_err(|_| io::Error::other("DATABASE_URL must be configured"))?;
    let pool = database::connect(&database_url)
        .await
        .map_err(io::Error::other)?;
    database::migrate(&pool).await.map_err(io::Error::other)?;
    if let Some(registration) = deployment_from_env()? {
        database::register_deployment(&pool, &registration)
            .await
            .map_err(io::Error::other)?;
        info!(
            chain_id = registration.chain_id,
            assets = registration.assets.len(),
            "registered token deployment"
        );
    }
    let catalog = database::load_catalog(&pool)
        .await
        .map_err(io::Error::other)?;
    let rpc_url = env::var("BASE_SEPOLIA_RPC_URL")
        .map_err(|_| io::Error::other("BASE_SEPOLIA_RPC_URL must be configured"))?;
    let chain = ChainClient::new(&rpc_url).map_err(io::Error::other)?;
    let google = env::var("GOOGLE_OAUTH_CLIENT_IDS")
        .ok()
        .and_then(|value| GoogleVerifier::new(value.split(',').map(str::to_owned).collect()));

    info!(%host, %port, "starting Tickerless API");

    let state = actix_web::web::Data::new(AppState::new(catalog, pool, chain).with_google(google));

    HttpServer::new(move || App::new().app_data(state.clone()).configure(configure_app))
        .bind((host, port))?
        .run()
        .await
}

fn deployment_from_env() -> io::Result<Option<DeploymentRegistration>> {
    if env::var("TICKERLESS_MARKET_ADDRESS").is_err() {
        return Ok(None);
    }
    let required = |name: &str| {
        env::var(name).map_err(|_| {
            io::Error::other(format!(
                "{name} must be configured when a market address is present"
            ))
        })
    };
    let address = |name: &str| {
        let value = required(name)?.to_ascii_lowercase();
        if value.len() != 42
            || !value.starts_with("0x")
            || !value[2..].bytes().all(|byte| byte.is_ascii_hexdigit())
        {
            return Err(io::Error::other(format!(
                "{name} must be a 20-byte hexadecimal address"
            )));
        }
        Ok(value)
    };
    let chain_id = required("TICKERLESS_CHAIN_ID")?
        .parse::<i64>()
        .map_err(|_| io::Error::other("TICKERLESS_CHAIN_ID must be a positive integer"))?;
    if chain_id <= 0 {
        return Err(io::Error::other("TICKERLESS_CHAIN_ID must be positive"));
    }
    let explorer_url = required("TICKERLESS_EXPLORER_URL")?;
    if !explorer_url.starts_with("https://") {
        return Err(io::Error::other(
            "TICKERLESS_EXPLORER_URL must be an HTTPS URL",
        ));
    }
    let mut assets = [
        ("tAAPLc", "TICKERLESS_AAPL_TOKEN_ADDRESS"),
        ("tNVDAc", "TICKERLESS_NVDA_TOKEN_ADDRESS"),
        ("tMETAc", "TICKERLESS_META_TOKEN_ADDRESS"),
        ("tGOOGLc", "TICKERLESS_GOOGL_TOKEN_ADDRESS"),
    ]
    .into_iter()
    .map(|(symbol, name)| Ok((symbol.to_owned(), address(name)?)))
    .collect::<io::Result<Vec<_>>>()?;
    if env::var("TICKERLESS_MSFT_TOKEN_ADDRESS").is_ok() {
        assets.push((
            "tMSFTc".to_owned(),
            address("TICKERLESS_MSFT_TOKEN_ADDRESS")?,
        ));
    }
    Ok(Some(DeploymentRegistration {
        market_address: address("TICKERLESS_MARKET_ADDRESS")?,
        payment_token_address: address("TICKERLESS_PAYMENT_TOKEN_ADDRESS")?,
        chain_id,
        explorer_url: explorer_url.trim_end_matches('/').to_owned(),
        assets,
    }))
}
