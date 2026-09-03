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
            normalize(theme)
                .split_whitespace()
                .all(|word| query.split_whitespace().any(|item| item == word))
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
            asset.contract_address.is_some() && asset.market_address.is_some()
        }),
        role: None,
    })
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
    Some(TokenizedAsset {
        symbol: symbol.to_owned(),
        network: "Base Sepolia".to_owned(),
        environment: "demo".to_owned(),
        contract_address: None,
        market_address: None,
        price_usdc: match symbol {
            "tAAPLc" => rust_decimal::Decimal::new(200, 0),
            "tNVDAc" => rust_decimal::Decimal::new(180, 0),
            "tMETAc" => rust_decimal::Decimal::new(500, 0),
            "tGOOGLc" => rust_decimal::Decimal::new(150, 0),
            _ => rust_decimal::Decimal::ZERO,
        },
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
            ]
            .into_iter()
            .map(str::to_owned)
            .collect(),
            themes: ["consumer technology", "smartphones", "personal computing"]
                .into_iter()
                .map(str::to_owned)
                .collect(),
            asset: asset("tAAPLc"),
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
                "company behind Instagram",
            ]
            .into_iter()
            .map(str::to_owned)
            .collect(),
            themes: ["social media", "virtual reality", "artificial intelligence"]
                .into_iter()
                .map(str::to_owned)
                .collect(),
            asset: asset("tMETAc"),
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
            asset: asset("tGOOGLc"),
        },
        Company {
            slug: "nvidia".to_owned(),
            name: "NVIDIA".to_owned(),
            ticker: "NVDA".to_owned(),
            description: "Computing company known for GPUs and accelerated AI infrastructure."
                .to_owned(),
            aliases: ["GeForce", "RTX", "CUDA", "DGX", "GeForce GPUs"]
                .into_iter()
                .map(str::to_owned)
                .collect(),
            themes: ["ai chips", "gpu infrastructure", "artificial intelligence"]
                .into_iter()
                .map(str::to_owned)
                .collect(),
            asset: asset("tNVDAc"),
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
}
