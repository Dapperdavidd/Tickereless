import 'package:flutter/material.dart';

/// Brand colours and bundled marks for a company.
///
/// This is presentation, not domain: the resolver returns a ticker, and the
/// app decides what that should look like. Anything unmapped falls back to
/// white and a generic chip icon rather than going blank.
abstract final class BrandPalette {
  static Color colorFor(String ticker) => switch (ticker) {
    'NVDA' => const Color(0xFF9BFF00),
    'META' => const Color(0xFF38A5FF),
    'GOOGL' => const Color(0xFF4285F4),
    'TSLA' => const Color(0xFFE82127),
    'MSFT' => const Color(0xFF00A4EF),
    'AMZN' => const Color(0xFFFF9900),
    'SPOT' => const Color(0xFF1DB954),
    _ => Colors.white,
  };

  /// Tickers with a bundled brand mark in `assets/logos/`.
  static const _bundledLogos = {
    'AAPL',
    'NVDA',
    'META',
    'TSLA',
    'SPOT',
    'AMZN',
    'GOOGL',
    'MSFT',
  };

  /// The company's own mark, or null when we do not ship one — the resolver
  /// can return any company, and most of them are not in the demo set.
  static String? logoAssetFor(String ticker) =>
      _bundledLogos.contains(ticker) ? 'assets/logos/$ticker.svg' : null;

  /// Text and glyph colour that stays legible on the brand colour — the light
  /// brands (Apple, NVIDIA) need dark ink, the saturated ones need white.
  static Color inkOn(String ticker) =>
      colorFor(ticker).computeLuminance() > .5 ? Colors.black : Colors.white;
}
