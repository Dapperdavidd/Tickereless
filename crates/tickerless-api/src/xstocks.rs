use reqwest::Client;
use rust_decimal::Decimal;
use serde::Deserialize;

const DEFAULT_BASE_URL: &str = "https://api.backed.fi/api/v2/public";

#[derive(Clone)]
pub struct XStocksClient {
    client: Client,
    base_url: String,
}

#[derive(Debug, Deserialize)]
struct PriceData {
    quote: Decimal,
}

#[derive(Debug)]
pub enum PriceError {
    Unavailable,
    Invalid,
}

impl XStocksClient {
    pub fn new(base_url: impl Into<String>) -> Self {
        Self {
            client: Client::new(),
            base_url: base_url.into().trim_end_matches('/').to_owned(),
        }
    }

    pub fn production() -> Self {
        Self::new(DEFAULT_BASE_URL)
    }

    pub async fn price(&self, symbol: &str) -> Result<Decimal, PriceError> {
        if symbol.is_empty() || !symbol.bytes().all(|byte| byte.is_ascii_alphanumeric()) {
            return Err(PriceError::Invalid);
        }
        let response = self
            .client
            .get(format!("{}/assets/{symbol}/price-data", self.base_url))
            .send()
            .await
            .map_err(|_| PriceError::Unavailable)?;
        if !response.status().is_success() {
            return Err(PriceError::Unavailable);
        }
        let data = response
            .json::<PriceData>()
            .await
            .map_err(|_| PriceError::Invalid)?;
        if data.quote <= Decimal::ZERO {
            return Err(PriceError::Invalid);
        }
        Ok(data.quote)
    }
}
