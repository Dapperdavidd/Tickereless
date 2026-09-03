use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Serialize)]
pub struct HealthResponse {
    pub status: &'static str,
    pub service: &'static str,
}

#[derive(Deserialize)]
pub struct SearchRequest {
    pub query: String,
}

#[derive(Deserialize)]
pub struct LinkRequest {
    pub url: String,
}

#[derive(Serialize)]
pub struct SearchResponse<'a> {
    pub query: String,
    pub matches: Vec<SearchMatch<'a>>,
}

#[derive(Serialize)]
pub struct SearchMatch<'a> {
    pub company: &'a Company,
    pub asset: Option<&'a TokenizedAsset>,
    pub reason: String,
    pub confidence: f32,
    pub actionable: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub role: Option<&'static str>,
}

#[derive(Serialize)]
pub struct LinkResolution<'a> {
    pub url: String,
    pub title: Option<String>,
    pub matches: Vec<SearchMatch<'a>>,
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

#[derive(Debug, Clone, Copy, Deserialize, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum DiscoveryMethod {
    Search,
    Lens,
    Link,
}

impl DiscoveryMethod {
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Search => "search",
            Self::Lens => "lens",
            Self::Link => "link",
        }
    }
}

#[derive(Deserialize)]
pub struct CreateDiscoveryRequest {
    pub company_slug: String,
    pub method: DiscoveryMethod,
    pub source: String,
    pub explanation: String,
    pub wallet_address: Option<String>,
}

#[derive(Deserialize)]
pub struct DiscoveryHistoryQuery {
    pub wallet_address: String,
    pub limit: Option<i64>,
}

#[derive(Serialize, FromRow)]
pub struct Discovery {
    pub id: Uuid,
    pub company_slug: String,
    pub company_name: String,
    pub ticker: String,
    pub method: String,
    pub source: String,
    pub explanation: String,
    pub created_at: DateTime<Utc>,
}
