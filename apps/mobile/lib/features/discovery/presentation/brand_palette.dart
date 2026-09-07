import 'package:flutter/material.dart';

/// Brand colour and glyph for a company.
///
/// This is presentation, not domain: the resolver returns a ticker, and the
/// app decides what that should look like. Anything unmapped falls back to
/// white and a generic chip icon rather than going blank.
abstract final class BrandPalette {
  static Color colorFor(String ticker) => switch (ticker) {
    'NVDA' => const Color(0xFF9BFF00),
    'META' => const Color(0xFF38A5FF),
    'GOOGL' => const Color(0xFF4285F4),
    _ => Colors.white,
  };

  static IconData iconFor(String ticker) => switch (ticker) {
    'AAPL' => Icons.apple,
    'META' => Icons.all_inclusive,
    'GOOGL' => Icons.g_mobiledata,
    _ => Icons.memory,
  };
}
