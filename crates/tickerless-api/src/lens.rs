use crate::{
    catalog::CompanyCatalog,
    models::{LensRequest, LensResolution},
};

const MAX_TEXT_CHARS: usize = 10_000;
const MAX_LABELS: usize = 50;
const MAX_LABEL_CHARS: usize = 100;

#[derive(Debug)]
pub enum LensError {
    EmptyInput,
    InputTooLarge,
}

pub fn resolve<'a>(
    catalog: &'a CompanyCatalog,
    input: LensRequest,
) -> Result<LensResolution<'a>, LensError> {
    if input
        .text
        .as_ref()
        .is_some_and(|text| text.chars().count() > MAX_TEXT_CHARS)
        || input.labels.len() > MAX_LABELS
        || input
            .labels
            .iter()
            .any(|label| label.chars().count() > MAX_LABEL_CHARS)
    {
        return Err(LensError::InputTooLarge);
    }

    let mut signals = Vec::new();
    if let Some(text) = input.text {
        let text = text.trim();
        if !text.is_empty() {
            signals.push(text.to_owned());
        }
    }
    for label in input.labels {
        let label = label.trim();
        if !label.is_empty()
            && !signals
                .iter()
                .any(|existing| existing.eq_ignore_ascii_case(label))
        {
            signals.push(label.to_owned());
        }
    }
    if signals.is_empty() {
        return Err(LensError::EmptyInput);
    }

    let mut matches = catalog.search(&signals.join(" ")).matches;
    for (index, item) in matches.iter_mut().enumerate() {
        item.role = Some(if index == 0 { "primary" } else { "mentioned" });
    }
    Ok(LensResolution { signals, matches })
}

#[cfg(test)]
mod tests {
    use crate::{catalog::CompanyCatalog, models::LensRequest};

    use super::{LensError, resolve};

    #[test]
    fn resolves_ocr_product_text() {
        let catalog = CompanyCatalog::seeded();
        let result = resolve(
            &catalog,
            LensRequest {
                text: Some("GEFORCE RTX".to_owned()),
                labels: vec!["graphics card".to_owned()],
            },
        )
        .expect("valid lens input");
        assert_eq!(result.matches[0].company.slug, "nvidia");
        assert_eq!(result.matches[0].role, Some("primary"));
    }

    #[test]
    fn resolves_a_broader_set_of_product_text() {
        let catalog = CompanyCatalog::seeded();
        for (text, expected) in [
            ("Designed for iOS", "apple"),
            ("Ray-Ban Meta smart glasses", "meta"),
            ("Shot on Google Pixel", "alphabet"),
            ("NVIDIA Jetson", "nvidia"),
        ] {
            let result = resolve(
                &catalog,
                LensRequest {
                    text: Some(text.to_owned()),
                    labels: vec![],
                },
            )
            .expect("valid lens input");
            assert_eq!(result.matches[0].company.slug, expected);
        }
    }

    #[test]
    fn rejects_empty_signals() {
        assert!(matches!(
            resolve(
                &CompanyCatalog::seeded(),
                LensRequest {
                    text: Some(" ".to_owned()),
                    labels: vec![]
                }
            ),
            Err(LensError::EmptyInput)
        ));
    }
}
