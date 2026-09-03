use std::{env, io};

use actix_web::{App, HttpServer};
use tickerless_api::configure_app;
use tracing::info;
use tracing_subscriber::EnvFilter;

const DEFAULT_HOST: &str = "127.0.0.1";
const DEFAULT_PORT: u16 = 8080;

#[actix_web::main]
async fn main() -> io::Result<()> {
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

    info!(%host, %port, "starting Tickerless API");

    HttpServer::new(|| App::new().configure(configure_app))
        .bind((host, port))?
        .run()
        .await
}
