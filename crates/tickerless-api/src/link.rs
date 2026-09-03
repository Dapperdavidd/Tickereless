use std::{net::SocketAddr, time::Duration};

use reqwest::{Client, redirect::Policy};
use scraper::{Html, Selector};
use url::Url;

use crate::{catalog::CompanyCatalog, models::LinkResolution};

const MAX_PAGE_BYTES: u64 = 1_000_000;

pub enum LinkError {
    InvalidUrl,
    UnsafeTarget,
    FetchFailed,
    RedirectNotAllowed,
    UnsupportedContent,
    PageTooLarge,
}

pub async fn resolve<'a>(
    catalog: &'a CompanyCatalog,
    input: &str,
) -> Result<LinkResolution<'a>, LinkError> {
    let url = validate_url(input)?;
    let host = url.host_str().ok_or(LinkError::InvalidUrl)?.to_owned();
    let port = url.port_or_known_default().ok_or(LinkError::InvalidUrl)?;
    let address = safe_address(&host, port).await?;
    let client = Client::builder()
        .timeout(Duration::from_secs(10))
        .redirect(Policy::none())
        .user_agent("Tickerless/0.1 (+https://github.com/Dapperdavidd/Tickereless)")
        .resolve(&host, address)
        .build()
        .map_err(|_| LinkError::FetchFailed)?;
    let response = client
        .get(url.clone())
        .send()
        .await
        .map_err(|_| LinkError::FetchFailed)?;
    if response.status().is_redirection() {
        return Err(LinkError::RedirectNotAllowed);
    }
    if !response.status().is_success() {
        return Err(LinkError::FetchFailed);
    }
    if response
        .content_length()
        .is_some_and(|length| length > MAX_PAGE_BYTES)
    {
        return Err(LinkError::PageTooLarge);
    }
    let content_type = response
        .headers()
        .get(reqwest::header::CONTENT_TYPE)
        .and_then(|value| value.to_str().ok())
        .unwrap_or_default()
        .to_owned();
    if !content_type.starts_with("text/html") && !content_type.starts_with("text/plain") {
        return Err(LinkError::UnsupportedContent);
    }
    let body = response.bytes().await.map_err(|_| LinkError::FetchFailed)?;
    if body.len() as u64 > MAX_PAGE_BYTES {
        return Err(LinkError::PageTooLarge);
    }
    let body = String::from_utf8_lossy(&body);
    let (title, content) = if content_type.starts_with("text/html") {
        extract_html(&body)
    } else {
        (None, body.into_owned())
    };
    let mut matches = title
        .as_deref()
        .map(|title| catalog.search(title).matches)
        .unwrap_or_default();
    for item in catalog.search(&content).matches {
        if !matches
            .iter()
            .any(|existing| existing.company.slug == item.company.slug)
        {
            matches.push(item);
        }
    }
    for (index, item) in matches.iter_mut().enumerate() {
        item.role = Some(if index == 0 { "primary" } else { "mentioned" });
    }
    Ok(LinkResolution {
        url: url.to_string(),
        title,
        matches,
    })
}

fn validate_url(input: &str) -> Result<Url, LinkError> {
    let url = Url::parse(input.trim()).map_err(|_| LinkError::InvalidUrl)?;
    if !matches!(url.scheme(), "http" | "https")
        || !url.username().is_empty()
        || url.password().is_some()
    {
        return Err(LinkError::InvalidUrl);
    }
    let host = url.host_str().ok_or(LinkError::InvalidUrl)?;
    if host.eq_ignore_ascii_case("localhost") || host.ends_with(".localhost") {
        return Err(LinkError::UnsafeTarget);
    }
    Ok(url)
}

async fn safe_address(host: &str, port: u16) -> Result<SocketAddr, LinkError> {
    let addresses: Vec<_> = tokio::net::lookup_host((host, port))
        .await
        .map_err(|_| LinkError::FetchFailed)?
        .collect();
    if addresses.is_empty() || addresses.iter().any(|address| !is_public_ip(address.ip())) {
        return Err(LinkError::UnsafeTarget);
    }
    Ok(addresses[0])
}

fn is_public_ip(ip: std::net::IpAddr) -> bool {
    match ip {
        std::net::IpAddr::V4(ip) => {
            let octets = ip.octets();
            !ip.is_private()
                && !ip.is_loopback()
                && !ip.is_link_local()
                && !ip.is_broadcast()
                && !ip.is_documentation()
                && !ip.is_unspecified()
                && !ip.is_multicast()
                && octets[0] != 0
                && !(octets[0] == 100 && (64..=127).contains(&octets[1]))
                && !(octets[0] == 198 && (18..=19).contains(&octets[1]))
                && octets[0] < 240
        }
        std::net::IpAddr::V6(ip) => {
            let segments = ip.segments();
            !(ip.is_loopback()
                || ip.is_unspecified()
                || ip.is_multicast()
                || (segments[0] & 0xe000) != 0x2000
                || (segments[0] == 0x2001 && segments[1] == 0x0db8))
        }
    }
}

fn extract_html(body: &str) -> (Option<String>, String) {
    let document = Html::parse_document(body);
    let title_selector = Selector::parse("title").expect("static selector is valid");
    let body_selector = Selector::parse("body").expect("static selector is valid");
    let title = document
        .select(&title_selector)
        .next()
        .map(|element| {
            element
                .text()
                .collect::<Vec<_>>()
                .join(" ")
                .trim()
                .to_owned()
        })
        .filter(|title| !title.is_empty());
    let content = document
        .select(&body_selector)
        .next()
        .map(|element| element.text().collect::<Vec<_>>().join(" "))
        .unwrap_or_else(|| document.root_element().text().collect::<Vec<_>>().join(" "));
    (title, content)
}

#[cfg(test)]
mod tests {
    use super::{LinkError, extract_html, validate_url};

    #[test]
    fn extracts_title_and_visible_text() {
        let (title, body) = extract_html(
            "<html><head><title>NVIDIA News</title></head><body>GeForce RTX</body></html>",
        );
        assert_eq!(title.as_deref(), Some("NVIDIA News"));
        assert_eq!(body, "GeForce RTX");
    }

    #[test]
    fn blocks_local_and_credentialed_urls() {
        assert!(matches!(
            validate_url("http://localhost/admin"),
            Err(LinkError::UnsafeTarget)
        ));
        assert!(matches!(
            validate_url("http://user:pass@example.com"),
            Err(LinkError::InvalidUrl)
        ));
        assert!(matches!(
            validate_url("file:///etc/passwd"),
            Err(LinkError::InvalidUrl)
        ));
    }
}
