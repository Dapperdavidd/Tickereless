use std::{
    collections::HashMap,
    sync::RwLock,
    time::{Duration, Instant, SystemTime, UNIX_EPOCH},
};

use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use reqwest::Client;
use ring::signature::{RSA_PKCS1_2048_8192_SHA256, RsaPublicKeyComponents};
use serde::Deserialize;

const GOOGLE_JWKS_URL: &str = "https://www.googleapis.com/oauth2/v3/certs";
const DEFAULT_CACHE_TTL: Duration = Duration::from_secs(3600);

pub struct GoogleVerifier {
    client: Client,
    audiences: Vec<String>,
    cache: RwLock<KeyCache>,
}

struct KeyCache {
    expires_at: Instant,
    keys: HashMap<String, GoogleKey>,
}

#[derive(Clone)]
struct GoogleKey {
    modulus: Vec<u8>,
    exponent: Vec<u8>,
}

#[derive(Deserialize)]
struct Header {
    alg: String,
    kid: String,
}

#[derive(Deserialize)]
struct Claims {
    iss: String,
    aud: Audience,
    exp: u64,
    sub: String,
    email: String,
    email_verified: bool,
}

#[derive(Deserialize)]
#[serde(untagged)]
enum Audience {
    One(String),
    Many(Vec<String>),
}

#[derive(Deserialize)]
struct JwkSet {
    keys: Vec<Jwk>,
}

#[derive(Deserialize)]
struct Jwk {
    kid: String,
    kty: String,
    alg: String,
    n: String,
    e: String,
}

pub struct GoogleIdentity {
    pub subject: String,
    pub email: String,
}

#[derive(Debug)]
pub enum VerifyError {
    Invalid,
    Unavailable,
}

impl GoogleVerifier {
    pub fn new(audiences: Vec<String>) -> Option<Self> {
        let audiences: Vec<_> = audiences
            .into_iter()
            .map(|value| value.trim().to_owned())
            .filter(|value| !value.is_empty())
            .collect();
        if audiences.is_empty() {
            return None;
        }
        Some(Self {
            client: Client::builder()
                .timeout(Duration::from_secs(10))
                .build()
                .ok()?,
            audiences,
            cache: RwLock::new(KeyCache {
                expires_at: Instant::now(),
                keys: HashMap::new(),
            }),
        })
    }

    pub async fn verify(&self, token: &str) -> Result<GoogleIdentity, VerifyError> {
        let mut segments = token.split('.');
        let (Some(header_segment), Some(payload_segment), Some(signature), None) = (
            segments.next(),
            segments.next(),
            segments.next(),
            segments.next(),
        ) else {
            return Err(VerifyError::Invalid);
        };
        let header: Header = decode_json(header_segment)?;
        let claims: Claims = decode_json(payload_segment)?;
        if header.alg != "RS256" || !valid_claims(&claims, &self.audiences) {
            return Err(VerifyError::Invalid);
        }
        let signature = URL_SAFE_NO_PAD
            .decode(signature)
            .map_err(|_| VerifyError::Invalid)?;
        let key = self.key(&header.kid).await?;
        RsaPublicKeyComponents {
            n: &key.modulus,
            e: &key.exponent,
        }
        .verify(
            &RSA_PKCS1_2048_8192_SHA256,
            format!("{header_segment}.{payload_segment}").as_bytes(),
            &signature,
        )
        .map_err(|_| VerifyError::Invalid)?;
        Ok(GoogleIdentity {
            subject: claims.sub,
            email: claims.email.to_ascii_lowercase(),
        })
    }

    async fn key(&self, key_id: &str) -> Result<GoogleKey, VerifyError> {
        if let Some(key) = self.cached_key(key_id) {
            return Ok(key);
        }
        let response = self
            .client
            .get(GOOGLE_JWKS_URL)
            .send()
            .await
            .map_err(|_| VerifyError::Unavailable)?
            .error_for_status()
            .map_err(|_| VerifyError::Unavailable)?;
        let ttl = response
            .headers()
            .get(reqwest::header::CACHE_CONTROL)
            .and_then(|value| value.to_str().ok())
            .and_then(cache_max_age)
            .unwrap_or(DEFAULT_CACHE_TTL);
        let jwks: JwkSet = response
            .json()
            .await
            .map_err(|_| VerifyError::Unavailable)?;
        let keys: HashMap<_, _> = jwks
            .keys
            .into_iter()
            .filter(|key| key.kty == "RSA" && key.alg == "RS256")
            .filter_map(|key| {
                Some((
                    key.kid,
                    GoogleKey {
                        modulus: URL_SAFE_NO_PAD.decode(key.n).ok()?,
                        exponent: URL_SAFE_NO_PAD.decode(key.e).ok()?,
                    },
                ))
            })
            .collect();
        let requested = keys.get(key_id).cloned().ok_or(VerifyError::Invalid)?;
        let mut cache = self.cache.write().map_err(|_| VerifyError::Unavailable)?;
        *cache = KeyCache {
            expires_at: Instant::now() + ttl,
            keys,
        };
        Ok(requested)
    }

    fn cached_key(&self, key_id: &str) -> Option<GoogleKey> {
        let cache = self.cache.read().ok()?;
        (cache.expires_at > Instant::now())
            .then(|| cache.keys.get(key_id).cloned())
            .flatten()
    }
}

fn decode_json<T: for<'de> Deserialize<'de>>(segment: &str) -> Result<T, VerifyError> {
    let bytes = URL_SAFE_NO_PAD
        .decode(segment)
        .map_err(|_| VerifyError::Invalid)?;
    serde_json::from_slice(&bytes).map_err(|_| VerifyError::Invalid)
}

fn valid_claims(claims: &Claims, audiences: &[String]) -> bool {
    let valid_issuer = matches!(
        claims.iss.as_str(),
        "accounts.google.com" | "https://accounts.google.com"
    );
    let valid_audience = match &claims.aud {
        Audience::One(value) => audiences.contains(value),
        Audience::Many(values) => values.iter().any(|value| audiences.contains(value)),
    };
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_or(u64::MAX, |duration| duration.as_secs());
    valid_issuer
        && valid_audience
        && claims.exp > now
        && claims.email_verified
        && !claims.sub.is_empty()
        && crate::auth::normalize_email(&claims.email).is_some()
}

fn cache_max_age(value: &str) -> Option<Duration> {
    value.split(',').find_map(|directive| {
        directive
            .trim()
            .strip_prefix("max-age=")?
            .parse::<u64>()
            .ok()
            .map(Duration::from_secs)
    })
}

#[cfg(test)]
mod tests {
    use super::{Audience, Claims, cache_max_age, valid_claims};
    use std::time::{SystemTime, UNIX_EPOCH};

    fn future() -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs()
            + 60
    }

    #[test]
    fn validates_google_issuer_audience_expiry_and_email() {
        let audiences = vec!["mobile-client.apps.googleusercontent.com".to_owned()];
        let claims = Claims {
            iss: "https://accounts.google.com".to_owned(),
            aud: Audience::One(audiences[0].clone()),
            exp: future(),
            sub: "google-user-1".to_owned(),
            email: "owner@example.com".to_owned(),
            email_verified: true,
        };
        assert!(valid_claims(&claims, &audiences));
    }

    #[test]
    fn parses_google_key_cache_ttl() {
        assert_eq!(
            cache_max_age("public, max-age=123, must-revalidate")
                .unwrap()
                .as_secs(),
            123
        );
    }
}
