use crate::models::{Company, SearchMatch, SearchResponse, TokenizedAsset};

pub struct CompanyCatalog {
    companies: Vec<Company>,
}

impl CompanyCatalog {
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

    pub fn search<'a>(&'a self, query: &'a str) -> SearchResponse<'a> {
        let query_normalized = normalize(query);
        let mut matches: Vec<_> = self
            .companies
            .iter()
            .filter_map(|company| score(company, &query_normalized))
            .collect();
        matches.sort_by(|a, b| b.confidence.total_cmp(&a.confidence));
        SearchResponse { query, matches }
    }
}

fn score<'a>(company: &'a Company, query: &str) -> Option<SearchMatch<'a>> {
    let direct = query == normalize(company.name) || query == normalize(company.ticker);
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
        .copied()
        .collect();
    let (confidence, reason) = if direct {
        (1.0, format!("Direct match for {}.", company.name))
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
        actionable: company.asset.is_some(),
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

fn asset(symbol: &'static str) -> Option<TokenizedAsset> {
    Some(TokenizedAsset {
        symbol,
        network: "Base Sepolia",
        environment: "demo",
        contract_address: None,
    })
}

fn seed_companies() -> Vec<Company> {
    vec![
        Company {
            slug: "apple",
            name: "Apple",
            ticker: "AAPL",
            description: "Consumer technology company behind iPhone, Mac, and other devices.",
            aliases: &[
                "iPhone",
                "Mac",
                "MacBook",
                "iPad",
                "AirPods",
                "Apple Watch",
                "Vision Pro",
                "iPhone maker",
            ],
            themes: &["consumer technology", "smartphones", "personal computing"],
            asset: asset("tAAPLc"),
        },
        Company {
            slug: "meta",
            name: "Meta Platforms",
            ticker: "META",
            description: "Technology company behind Instagram, WhatsApp, Facebook, and Threads.",
            aliases: &[
                "Meta",
                "Instagram",
                "WhatsApp",
                "Facebook",
                "Threads",
                "Quest",
                "company behind Instagram",
            ],
            themes: &["social media", "virtual reality", "artificial intelligence"],
            asset: asset("tMETAc"),
        },
        Company {
            slug: "alphabet",
            name: "Alphabet",
            ticker: "GOOGL",
            description: "Technology company behind Google, YouTube, Android, and Google Cloud.",
            aliases: &[
                "Google",
                "YouTube",
                "Gemini",
                "Android",
                "Chrome",
                "Google Cloud",
                "Waymo",
                "company behind YouTube",
            ],
            themes: &[
                "search engines",
                "cloud computing",
                "artificial intelligence",
            ],
            asset: asset("tGOOGLc"),
        },
        Company {
            slug: "nvidia",
            name: "NVIDIA",
            ticker: "NVDA",
            description: "Computing company known for GPUs and accelerated AI infrastructure.",
            aliases: &["GeForce", "RTX", "CUDA", "DGX", "GeForce GPUs"],
            themes: &["ai chips", "gpu infrastructure", "artificial intelligence"],
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
