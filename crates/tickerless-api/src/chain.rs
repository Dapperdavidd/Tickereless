use std::time::Duration;

use reqwest::Client;
use rust_decimal::Decimal;
use serde::{Deserialize, de::DeserializeOwned};
use serde_json::json;
use url::Url;

const BUY_SELECTOR: &str = "a59ac6dd";
const PURCHASED_TOPIC: &str = "0xa326259ec721617acd3cb2a00bcbeac91eefe409880e49aa2bbf473ed648da49";

pub struct ChainClient {
    client: Client,
    rpc_url: Url,
}

pub struct VerifiedPurchase {
    pub amount_usdc: Decimal,
    pub token_amount: Decimal,
}

#[derive(Debug)]
pub enum VerifyError {
    InvalidTransactionHash,
    Pending,
    Reverted,
    Mismatch,
    Rpc,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct Transaction {
    from: String,
    to: Option<String>,
    input: String,
}

#[derive(Deserialize)]
struct Receipt {
    status: String,
    logs: Vec<Log>,
}

#[derive(Deserialize)]
struct Log {
    address: String,
    topics: Vec<String>,
    data: String,
}

#[derive(Deserialize)]
struct RpcResponse<T> {
    result: Option<T>,
    error: Option<serde_json::Value>,
}

impl ChainClient {
    pub fn new(rpc_url: &str) -> Result<Self, url::ParseError> {
        Ok(Self {
            client: Client::builder()
                .timeout(Duration::from_secs(10))
                .build()
                .expect("HTTP client configuration is valid"),
            rpc_url: Url::parse(rpc_url)?,
        })
    }

    pub async fn verify_purchase(
        &self,
        tx_hash: &str,
        wallet: &str,
        market: &str,
        asset: &str,
        chain_id: i64,
    ) -> Result<VerifiedPurchase, VerifyError> {
        if !valid_hash(tx_hash) {
            return Err(VerifyError::InvalidTransactionHash);
        }
        let remote_chain: String = self.rpc("eth_chainId", json!([])).await?;
        let remote_chain = parse_hex_u128(&remote_chain).ok_or(VerifyError::Rpc)?;
        if remote_chain != chain_id as u128 {
            return Err(VerifyError::Mismatch);
        }

        let transaction: Option<Transaction> = self
            .rpc("eth_getTransactionByHash", json!([tx_hash]))
            .await?;
        let transaction = transaction.ok_or(VerifyError::Pending)?;
        let receipt: Option<Receipt> = self
            .rpc("eth_getTransactionReceipt", json!([tx_hash]))
            .await?;
        let receipt = receipt.ok_or(VerifyError::Pending)?;
        if receipt.status != "0x1" {
            return Err(VerifyError::Reverted);
        }
        if !same_address(&transaction.from, wallet)
            || transaction
                .to
                .as_deref()
                .is_none_or(|to| !same_address(to, market))
        {
            return Err(VerifyError::Mismatch);
        }
        let (called_asset, called_amount) =
            decode_buy(&transaction.input).ok_or(VerifyError::Mismatch)?;
        if !same_address(&called_asset, asset) {
            return Err(VerifyError::Mismatch);
        }
        let (event_amount, token_amount) = receipt
            .logs
            .iter()
            .find_map(|log| decode_purchase(log, wallet, market, asset))
            .ok_or(VerifyError::Mismatch)?;
        if called_amount != event_amount {
            return Err(VerifyError::Mismatch);
        }
        Ok(VerifiedPurchase {
            amount_usdc: decimal(event_amount, 6).ok_or(VerifyError::Mismatch)?,
            token_amount: decimal(token_amount, 18).ok_or(VerifyError::Mismatch)?,
        })
    }

    async fn rpc<T: DeserializeOwned>(
        &self,
        method: &str,
        params: serde_json::Value,
    ) -> Result<T, VerifyError> {
        let response = self
            .client
            .post(self.rpc_url.clone())
            .json(&json!({"jsonrpc":"2.0","id":1,"method":method,"params":params}))
            .send()
            .await
            .map_err(|_| VerifyError::Rpc)?
            .error_for_status()
            .map_err(|_| VerifyError::Rpc)?
            .json::<RpcResponse<T>>()
            .await
            .map_err(|_| VerifyError::Rpc)?;
        if response.error.is_some() {
            return Err(VerifyError::Rpc);
        }
        response.result.ok_or(VerifyError::Rpc)
    }
}

fn valid_hash(value: &str) -> bool {
    value.len() == 66
        && value.starts_with("0x")
        && value[2..].bytes().all(|byte| byte.is_ascii_hexdigit())
}

fn same_address(left: &str, right: &str) -> bool {
    left.eq_ignore_ascii_case(right)
}

fn decode_buy(input: &str) -> Option<(String, u128)> {
    let input = input.strip_prefix("0x")?;
    if input.len() < 8 + 64 * 3 || !input[..8].eq_ignore_ascii_case(BUY_SELECTOR) {
        return None;
    }
    let asset_word = &input[8..72];
    let amount_word = &input[72..136];
    let asset = format!("0x{}", &asset_word[24..]);
    Some((asset, u128::from_str_radix(amount_word, 16).ok()?))
}

fn decode_purchase(log: &Log, wallet: &str, market: &str, asset: &str) -> Option<(u128, u128)> {
    if !same_address(&log.address, market)
        || log.topics.len() != 3
        || !log.topics[0].eq_ignore_ascii_case(PURCHASED_TOPIC)
        || !topic_address(&log.topics[1]).is_some_and(|value| same_address(&value, wallet))
        || !topic_address(&log.topics[2]).is_some_and(|value| same_address(&value, asset))
    {
        return None;
    }
    let data = log.data.strip_prefix("0x")?;
    if data.len() != 128 {
        return None;
    }
    Some((
        u128::from_str_radix(&data[..64], 16).ok()?,
        u128::from_str_radix(&data[64..], 16).ok()?,
    ))
}

fn topic_address(topic: &str) -> Option<String> {
    let topic = topic.strip_prefix("0x")?;
    (topic.len() == 64).then(|| format!("0x{}", &topic[24..]))
}

fn parse_hex_u128(value: &str) -> Option<u128> {
    u128::from_str_radix(value.strip_prefix("0x")?, 16).ok()
}

fn decimal(value: u128, scale: u32) -> Option<Decimal> {
    Some(Decimal::from_i128_with_scale(value.try_into().ok()?, scale))
}

#[cfg(test)]
mod tests {
    use super::{Log, decode_buy, decode_purchase, valid_hash};

    const WALLET: &str = "0x00000000000000000000000000000000000000b0";
    const MARKET: &str = "0x0000000000000000000000000000000000000010";
    const ASSET: &str = "0x0000000000000000000000000000000000000040";

    #[test]
    fn decodes_market_call_and_purchase_event() {
        let input = format!(
            "0xa59ac6dd{:0>64}{:0>64}{:0>64}",
            &ASSET[2..],
            "895440",
            "0"
        );
        let (asset, amount) = decode_buy(&input).expect("valid buy calldata");
        assert_eq!(asset, ASSET);
        assert_eq!(amount, 9_000_000);
        let log = Log {
            address: MARKET.to_owned(),
            topics: vec![
                super::PURCHASED_TOPIC.to_owned(),
                format!("0x{:0>64}", &WALLET[2..]),
                format!("0x{:0>64}", &ASSET[2..]),
            ],
            data: format!("0x{:0>64}{:0>64}", "895440", "b1a2bc2ec50000"),
        };
        assert_eq!(
            decode_purchase(&log, WALLET, MARKET, ASSET),
            Some((9_000_000, 50_000_000_000_000_000))
        );
    }

    #[test]
    fn validates_transaction_hash_shape() {
        assert!(valid_hash(&format!("0x{}", "ab".repeat(32))));
        assert!(!valid_hash("0x1234"));
    }
}
