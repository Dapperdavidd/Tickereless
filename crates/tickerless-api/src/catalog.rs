use crate::models::{Company, SearchMatch, SearchResponse, TokenizedAsset};

pub struct CompanyCatalog {
    companies: Vec<Company>,
}

impl CompanyCatalog {
    pub fn new(companies: Vec<Company>) -> Self {
        Self { companies }
    }

    pub fn seeded() -> Self {
        Self {
            companies: seed_companies(),
        }
    }

    pub fn find_by_slug(&self, slug: &str) -> Option<&Company> {
        self.companies
            .iter()
            .find(|company| company.slug.eq_ignore_ascii_case(slug))
    }

    pub fn search<'a>(&'a self, query: &str) -> SearchResponse<'a> {
        let query_normalized = normalize(query);
        let mut matches: Vec<_> = self
            .companies
            .iter()
            .filter_map(|company| score(company, &query_normalized))
            .collect();
        matches.sort_by(|a, b| b.confidence.total_cmp(&a.confidence));
        SearchResponse {
            query: query.to_owned(),
            matches,
        }
    }
}

fn score<'a>(company: &'a Company, query: &str) -> Option<SearchMatch<'a>> {
    let direct = query == normalize(&company.name) || query == normalize(&company.ticker);
    let alias = company
        .aliases
        .iter()
        .find(|alias| phrase(query, &normalize(alias)));
    let themes: Vec<_> = company
        .themes
        .iter()
        .filter(|theme| {
            normalize(theme).split_whitespace().all(|word| {
                query
                    .split_whitespace()
                    .any(|item| equivalent_word(item, word))
            })
        })
        .map(String::as_str)
        .collect();
    let (confidence, reason) = if direct {
        (1.0, format!("Direct match for {}.", company.name))
    } else if phrase(query, &normalize(&company.name)) || phrase(query, &normalize(&company.ticker))
    {
        (
            0.98,
            format!("The content directly references {}.", company.name),
        )
    } else if let Some(alias) = alias {
        (
            0.95,
            format!("{alias} is associated with {}.", company.name),
        )
    } else if !themes.is_empty() {
        (
            0.75,
            format!("{} is active in {}.", company.name, themes.join(", ")),
        )
    } else {
        return None;
    };
    Some(SearchMatch {
        company,
        asset: company.asset.as_ref(),
        reason,
        confidence,
        actionable: company.asset.as_ref().is_some_and(|asset| {
            let has_verified_solana_deployment = asset.network == "Solana"
                && asset.contract_address.is_some()
                && asset.payment_token_address.is_some();
            let has_complete_evm_deployment = asset.contract_address.is_some()
                && asset.market_address.is_some()
                && asset.payment_token_address.is_some()
                && asset.chain_id.is_some();
            has_verified_solana_deployment || has_complete_evm_deployment
        }),
        role: None,
    })
}

fn equivalent_word(left: &str, right: &str) -> bool {
    left == right || singular(left) == singular(right)
}

fn singular(word: &str) -> &str {
    word.strip_suffix('s')
        .filter(|stem| stem.len() > 2)
        .unwrap_or(word)
}

fn normalize(value: &str) -> String {
    value
        .chars()
        .map(|c| {
            if c.is_alphanumeric() {
                c.to_ascii_lowercase()
            } else {
                ' '
            }
        })
        .collect::<String>()
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
}

fn phrase(haystack: &str, needle: &str) -> bool {
    format!(" {haystack} ").contains(&format!(" {needle} "))
}

fn asset(symbol: &str) -> Option<TokenizedAsset> {
    let (mint, price_usdc) = match symbol {
        "AAPLx" => (
            "XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp",
            rust_decimal::Decimal::new(331_460, 3),
        ),
        "NVDAx" => (
            "Xsc9qvGR1efVDFGLrVsmkzv3qi45LTBjeUKSPmx9qEh",
            rust_decimal::Decimal::new(232_885, 3),
        ),
        "METAx" => (
            "Xsa62P5mvPszXL1krVUnU5ar38bBSVcWAB6fmPCo5Zu",
            rust_decimal::Decimal::new(730_375, 3),
        ),
        "GOOGLx" => (
            "XsCPL9dNWBMvFtTmwcCA5v3xWPSMEBCszbQdiLLq6aN",
            rust_decimal::Decimal::new(341_115, 3),
        ),
        "MSFTx" => (
            "XspzcW1PRtgf6Wj92HCiZdjzKCyFekVD8P5Ueh3dRMX",
            rust_decimal::Decimal::new(516_890, 3),
        ),
        "AMZNx" => (
            "Xs3eBt7uRfJX8QUs4suhyU8p2M6DoUDrJyWBa8LLZsg",
            rust_decimal::Decimal::new(249_751, 3),
        ),
        "TSLAx" => (
            "XsDoVfqeBukxuZHWhdvWHBhgEHjGNst4MLodqsJHzoB",
            rust_decimal::Decimal::new(357_780, 3),
        ),
        _ => return None,
    };
    Some(TokenizedAsset {
        symbol: symbol.to_owned(),
        network: "Solana".to_owned(),
        environment: "mainnet".to_owned(),
        contract_address: Some(mint.to_owned()),
        market_address: None,
        payment_token_address: Some("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v".to_owned()),
        chain_id: None,
        explorer_url: Some(format!("https://explorer.solana.com/address/{mint}")),
        price_usdc,
    })
}

fn seed_companies() -> Vec<Company> {
    vec![
        Company {
            slug: "apple".to_owned(),
            name: "Apple".to_owned(),
            ticker: "AAPL".to_owned(),
            description: "Consumer technology company behind iPhone, Mac, and other devices."
                .to_owned(),
            aliases: [
                "iPhone",
                "Mac",
                "MacBook",
                "iPad",
                "AirPods",
                "Apple Watch",
                "Vision Pro",
                "iPhone maker",
                "iOS",
                "App Store",
                "Safari",
                "Beats",
                "Apple TV",
                "Apple Music",
                "Apple Intelligence",
                "Apple Pencil",
                "HomePod",
                "iMac",
            ]
            .into_iter()
            .map(str::to_owned)
            .collect(),
            themes: ["consumer technology", "smartphones", "personal computing"]
                .into_iter()
                .map(str::to_owned)
                .collect(),
            asset: asset("AAPLx"),
        },
        Company {
            slug: "meta".to_owned(),
            name: "Meta Platforms".to_owned(),
            ticker: "META".to_owned(),
            description: "Technology company behind Instagram, WhatsApp, Facebook, and Threads."
                .to_owned(),
            aliases: [
                "Meta",
                "Instagram",
                "WhatsApp",
                "Facebook",
                "Threads",
                "Quest",
                "Messenger",
                "Oculus",
                "Horizon",
                "Ray-Ban Meta",
                "Meta Quest",
                "Meta AI",
                "company behind Instagram",
            ]
            .into_iter()
            .map(str::to_owned)
            .collect(),
            themes: ["social media", "virtual reality", "artificial intelligence"]
                .into_iter()
                .map(str::to_owned)
                .collect(),
            asset: asset("METAx"),
        },
        Company {
            slug: "alphabet".to_owned(),
            name: "Alphabet".to_owned(),
            ticker: "GOOGL".to_owned(),
            description: "Technology company behind Google, YouTube, Android, and Google Cloud."
                .to_owned(),
            aliases: [
                "Google",
                "YouTube",
                "Gemini",
                "Android",
                "Chrome",
                "Google Cloud",
                "Waymo",
                "Gmail",
                "Google Maps",
                "Pixel",
                "Google Photos",
                "Nest",
                "Chromebook",
                "Google Pixel",
                "Pixel Watch",
                "Pixel Buds",
                "Google Play",
                "company behind YouTube",
            ]
            .into_iter()
            .map(str::to_owned)
            .collect(),
            themes: [
                "search engines",
                "cloud computing",
                "artificial intelligence",
            ]
            .into_iter()
            .map(str::to_owned)
            .collect(),
            asset: asset("GOOGLx"),
        },
        Company {
            slug: "nvidia".to_owned(),
            name: "NVIDIA".to_owned(),
            ticker: "NVDA".to_owned(),
            description: "Computing company known for GPUs and accelerated AI infrastructure."
                .to_owned(),
            aliases: [
                "GeForce",
                "RTX",
                "CUDA",
                "DGX",
                "GeForce GPUs",
                "Omniverse",
                "TensorRT",
                "NVIDIA Shield",
                "Jetson",
                "G-SYNC",
                "GeForce RTX",
                "GeForce GTX",
                "GeForce NOW",
                "Grace Hopper",
            ]
            .into_iter()
            .map(str::to_owned)
            .collect(),
            themes: ["ai chips", "gpu infrastructure", "artificial intelligence"]
                .into_iter()
                .map(str::to_owned)
                .collect(),
            asset: asset("NVDAx"),
        },
        Company {
            slug: "microsoft".to_owned(),
            name: "Microsoft".to_owned(),
            ticker: "MSFT".to_owned(),
            description: "Technology company behind Windows, Surface, Xbox, Azure, and Copilot."
                .to_owned(),
            aliases: [
                "Windows",
                "Surface",
                "Surface Laptop",
                "Surface Pro",
                "Xbox",
                "Azure",
                "Copilot",
                "Microsoft 365",
                "Office",
                "Teams",
            ]
            .into_iter()
            .map(str::to_owned)
            .collect(),
            themes: ["personal computing", "cloud computing", "gaming"]
                .into_iter()
                .map(str::to_owned)
                .collect(),
            asset: asset("MSFTx"),
        },
        Company {
            slug: "amazon".to_owned(),
            name: "Amazon".to_owned(),
            ticker: "AMZN".to_owned(),
            description: "Commerce and cloud-computing company behind Amazon and AWS.".to_owned(),
            aliases: ["Amazon", "AWS", "Prime", "Alexa", "Kindle", "Audible"]
                .into_iter()
                .map(str::to_owned)
                .collect(),
            themes: ["ecommerce", "cloud computing"]
                .into_iter()
                .map(str::to_owned)
                .collect(),
            asset: asset("AMZNx"),
        },
        Company {
            slug: "tesla".to_owned(),
            name: "Tesla".to_owned(),
            ticker: "TSLA".to_owned(),
            description: "Electric vehicle, energy storage, and charging company.".to_owned(),
            aliases: [
                "Tesla",
                "Model 3",
                "Model Y",
                "Cybertruck",
                "Supercharger",
                "Powerwall",
            ]
            .into_iter()
            .map(str::to_owned)
            .collect(),
            themes: ["electric vehicles", "energy storage"]
                .into_iter()
                .map(str::to_owned)
                .collect(),
            asset: asset("TSLAx"),
        },
    ]
}

#[cfg(test)]
mod tests {
    use super::CompanyCatalog;
    #[test]
    fn avoids_partial_word_aliases() {
        assert!(
            CompanyCatalog::seeded()
                .search("metal manufacturing")
                .matches
                .is_empty()
        );
    }
    #[test]
    fn conceptual_search_returns_multiple_companies() {
        assert_eq!(
            CompanyCatalog::seeded()
                .search("artificial intelligence companies")
                .matches
                .len(),
            3
        );
    }

    #[test]
    fn natural_language_tolerates_singular_and_plural_themes() {
        let catalog = CompanyCatalog::seeded();
        let matches = catalog.search("AI chip companies").matches;
        assert_eq!(matches[0].company.slug, "nvidia");
    }
}
