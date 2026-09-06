use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use rand::RngCore;
use ring::pbkdf2;
use sha2::{Digest, Sha256};
use std::{num::NonZeroU32, sync::OnceLock};

pub const SESSION_TTL_DAYS: i64 = 30;
const PASSWORD_ITERATIONS: u32 = 600_000;

pub fn normalize_email(value: &str) -> Option<String> {
    let email = value.trim().to_ascii_lowercase();
    let (local, domain) = email.split_once('@')?;
    if email.len() > 254
        || local.is_empty()
        || local.len() > 64
        || domain.is_empty()
        || !domain.contains('.')
        || email.chars().any(char::is_whitespace)
    {
        return None;
    }
    Some(email)
}

pub fn valid_password(value: &str) -> bool {
    (10..=128).contains(&value.chars().count())
}

pub fn hash_password(password: &str) -> String {
    let mut salt = [0_u8; 16];
    rand::rng().fill_bytes(&mut salt);
    let mut derived = [0_u8; 32];
    pbkdf2::derive(
        pbkdf2::PBKDF2_HMAC_SHA256,
        NonZeroU32::new(PASSWORD_ITERATIONS).expect("iteration count is non-zero"),
        &salt,
        password.as_bytes(),
        &mut derived,
    );
    format!(
        "pbkdf2-sha256${PASSWORD_ITERATIONS}${}${}",
        URL_SAFE_NO_PAD.encode(salt),
        URL_SAFE_NO_PAD.encode(derived)
    )
}

pub fn verify_password(password: &str, encoded: &str) -> bool {
    let mut fields = encoded.split('$');
    let Some(("pbkdf2-sha256", iterations, salt, expected)) = fields
        .next()
        .zip(fields.next())
        .zip(fields.next())
        .zip(fields.next())
        .map(|(((algorithm, iterations), salt), expected)| (algorithm, iterations, salt, expected))
    else {
        return false;
    };
    if fields.next().is_some() {
        return false;
    }
    let Ok(iterations) = iterations.parse::<u32>() else {
        return false;
    };
    if iterations != PASSWORD_ITERATIONS {
        return false;
    }
    let (Ok(salt), Ok(expected)) = (
        URL_SAFE_NO_PAD.decode(salt),
        URL_SAFE_NO_PAD.decode(expected),
    ) else {
        return false;
    };
    let Some(iterations) = NonZeroU32::new(iterations) else {
        return false;
    };
    pbkdf2::verify(
        pbkdf2::PBKDF2_HMAC_SHA256,
        iterations,
        &salt,
        password.as_bytes(),
        &expected,
    )
    .is_ok()
}

pub fn dummy_password_hash() -> &'static str {
    static HASH: OnceLock<String> = OnceLock::new();
    HASH.get_or_init(|| hash_password("tickerless-dummy-password"))
}

pub fn new_session_token() -> (String, Vec<u8>) {
    let mut bytes = [0_u8; 32];
    rand::rng().fill_bytes(&mut bytes);
    let token = URL_SAFE_NO_PAD.encode(bytes);
    let token_hash = hash_session_token(&token);
    (token, token_hash)
}

pub fn hash_session_token(token: &str) -> Vec<u8> {
    Sha256::digest(token.as_bytes()).to_vec()
}

pub fn bearer_token(value: Option<&str>) -> Option<&str> {
    value?
        .strip_prefix("Bearer ")
        .filter(|token| !token.is_empty())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn normalizes_reasonable_email_addresses() {
        assert_eq!(
            normalize_email("  Demo.User@Example.COM "),
            Some("demo.user@example.com".to_owned())
        );
        assert_eq!(normalize_email("not-an-email"), None);
        assert_eq!(normalize_email("a@localhost"), None);
    }

    #[test]
    fn hashes_and_verifies_passwords() {
        let hash = hash_password("correct horse battery staple");
        assert!(verify_password("correct horse battery staple", &hash));
        assert!(!verify_password("wrong password", &hash));
        assert!(!hash.contains("correct horse"));
    }

    #[test]
    fn session_tokens_are_random_and_hashable() {
        let (first, first_hash) = new_session_token();
        let (second, _) = new_session_token();
        assert_ne!(first, second);
        assert_eq!(first_hash, hash_session_token(&first));
        assert_eq!(first_hash.len(), 32);
    }
}
