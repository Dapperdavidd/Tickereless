use std::{env, io};

use actix_web::{App, HttpServer};
use tickerless_api::{AppState, configure_app, database};
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
    let port = env::var("TICKERLESS_API_PORT")
        .ok()
        .and_then(|value| value.parse().ok())
        .unwrap_or(DEFAULT_PORT);

    let database_url = env::var("DATABASE_URL")
        .map_err(|_| io::Error::other("DATABASE_URL must be configured"))?;
    let pool = database::connect(&database_url)
        .await
        .map_err(io::Error::other)?;
    database::migrate(&pool).await.map_err(io::Error::other)?;
    let catalog = database::load_catalog(&pool)
        .await
        .map_err(io::Error::other)?;

    info!(%host, %port, "starting Tickerless API");

    let state = actix_web::web::Data::new(AppState::new(catalog, pool));

    HttpServer::new(move || App::new().app_data(state.clone()).configure(configure_app))
        .bind((host, port))?
        .run()
        .await
}
