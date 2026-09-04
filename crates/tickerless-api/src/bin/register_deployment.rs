use std::{env, error::Error, io};

use tickerless_api::database::{self, DeploymentRegistration};
use url::Url;

#[actix_web::main]
async fn main() -> Result<(), Box<dyn Error>> {
    dotenvy::dotenv().ok();
    let database_url = required("DATABASE_URL")?;
    let registration = DeploymentRegistration {
        market_address: address("TICKERLESS_MARKET_ADDRESS")?,
        payment_token_address: address("TICKERLESS_PAYMENT_TOKEN_ADDRESS")?,
        chain_id: required("TICKERLESS_CHAIN_ID")?.parse()?,
        explorer_url: explorer_url()?,
        assets: vec![
            (
                "tAAPLc".to_owned(),
                address("TICKERLESS_AAPL_TOKEN_ADDRESS")?,
            ),
            (
                "tNVDAc".to_owned(),
                address("TICKERLESS_NVDA_TOKEN_ADDRESS")?,
            ),
            (
                "tMETAc".to_owned(),
                address("TICKERLESS_META_TOKEN_ADDRESS")?,
            ),
            (
                "tGOOGLc".to_owned(),
                address("TICKERLESS_GOOGL_TOKEN_ADDRESS")?,
            ),
        ],
    };
    if registration.chain_id <= 0 {
        return Err(io::Error::other("TICKERLESS_CHAIN_ID must be positive").into());
    }

    let pool = database::connect(&database_url).await?;
    database::migrate(&pool).await?;
    database::register_deployment(&pool, &registration).await?;
    println!(
        "registered {} demo assets for chain {}",
        registration.assets.len(),
        registration.chain_id
    );
    Ok(())
}

fn required(name: &str) -> Result<String, io::Error> {
    env::var(name).map_err(|_| io::Error::other(format!("{name} must be configured")))
}

fn address(name: &str) -> Result<String, io::Error> {
    let value = required(name)?.to_ascii_lowercase();
    if !valid_address(&value) {
        return Err(io::Error::other(format!(
            "{name} must be a 20-byte hexadecimal address"
        )));
    }
    Ok(value)
}

fn valid_address(value: &str) -> bool {
    value.len() == 42
        && value.starts_with("0x")
        && value[2..].bytes().all(|byte| byte.is_ascii_hexdigit())
}

fn explorer_url() -> Result<String, io::Error> {
    let value = required("TICKERLESS_EXPLORER_URL")?;
    let parsed =
        Url::parse(&value).map_err(|_| io::Error::other("TICKERLESS_EXPLORER_URL is invalid"))?;
    if parsed.scheme() != "https" || parsed.host_str().is_none() {
        return Err(io::Error::other(
            "TICKERLESS_EXPLORER_URL must be an HTTPS URL",
        ));
    }
    Ok(value.trim_end_matches('/').to_owned())
}

#[cfg(test)]
mod tests {
    use super::valid_address;

    #[test]
    fn validates_contract_address_shape() {
        assert!(valid_address("0x0000000000000000000000000000000000000001"));
        assert!(!valid_address("0x1234"));
        assert!(!valid_address("0xzz00000000000000000000000000000000000000"));
    }
}
