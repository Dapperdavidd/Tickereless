use serde::{Deserialize, Serialize};

#[derive(Serialize)]
pub struct HealthResponse {
    pub status: &'static str,
    pub service: &'static str,
}

#[derive(Deserialize)]
pub struct SearchRequest {
    pub query: String,
}

#[derive(Serialize)]
pub struct SearchResponse<'a> {
    pub query: &'a str,
    pub matches: Vec<SearchMatch<'a>>,
}

#[derive(Serialize)]
pub struct SearchMatch<'a> {
    pub company: &'a Company,
    pub asset: Option<&'a TokenizedAsset>,
    pub reason: String,
    pub confidence: f32,
    pub actionable: bool,
}

#[derive(Serialize)]
pub struct Company {
    pub slug: String,
    pub name: String,
    pub ticker: String,
    pub description: String,
    pub aliases: Vec<String>,
    pub themes: Vec<String>,
    pub asset: Option<TokenizedAsset>,
}

#[derive(Serialize)]
pub struct TokenizedAsset {
    pub symbol: String,
    pub network: String,
    pub environment: String,
    pub contract_address: Option<String>,
}

#[derive(Serialize)]
pub struct ApiError {
    pub code: &'static str,
    pub message: &'static str,
}
impl ApiError {
    pub const fn new(code: &'static str, message: &'static str) -> Self {
        Self { code, message }
    }
}
