import 'package:tickerless/features/discovery/domain/entities/company.dart';

/// The companies the demo ships with — what the Discover grid shows and what
/// the screens fall back to before the resolver has answered.
///
/// Prices and daily changes are fixed demo values, not quotes.
abstract final class DemoCompanies {
  static const apple = Company(
    name: 'Apple',
    ticker: 'AAPL',
    symbol: 'tAAPLc',
    description: 'The company behind iPhone, Mac, iPad, AirPods and more.',
    products: ['iPhone', 'Mac', 'AirPods'],
    price: 214.32,
    change: 1.81,
  );

  static const meta = Company(
    name: 'Meta Platforms',
    ticker: 'META',
    symbol: 'tMETAc',
    description:
        'The parent company of Instagram, WhatsApp, Facebook and Threads.',
    products: ['Instagram', 'WhatsApp', 'Threads'],
    price: 500,
    change: 1.2,
  );

  static const nvidia = Company(
    name: 'NVIDIA',
    ticker: 'NVDA',
    symbol: 'tNVDAc',
    description:
        'The computing company behind GeForce, RTX, CUDA and accelerated AI.',
    products: ['GeForce', 'RTX', 'CUDA'],
    price: 180,
    change: 2.4,
  );

  static const alphabet = Company(
    name: 'Alphabet',
    ticker: 'GOOGL',
    symbol: 'tGOOGLc',
    description:
        'The company behind Google Search, YouTube, Android, Gemini and more.',
    products: ['Google', 'YouTube', 'Gemini'],
    price: 150,
    change: 1.09,
  );

  static const tesla = Company(
    name: 'Tesla',
    ticker: 'TSLA',
    symbol: 'tTSLAc',
    description:
        'The company behind Model 3, Model Y, Powerwall and the Supercharger network.',
    products: ['Model Y', 'Powerwall', 'Supercharger'],
    price: 248.5,
    change: 2.94,
  );

  static const microsoft = Company(
    name: 'Microsoft',
    ticker: 'MSFT',
    symbol: 'tMSFTc',
    description: 'The company behind Windows, Office, Xbox, Azure and Copilot.',
    products: ['Windows', 'Xbox', 'Azure'],
    price: 430.2,
    change: .74,
  );

  static const amazon = Company(
    name: 'Amazon',
    ticker: 'AMZN',
    symbol: 'tAMZNc',
    description: 'The company behind Amazon, Prime, Kindle, Alexa and AWS.',
    products: ['Prime', 'Kindle', 'AWS'],
    price: 186.4,
    change: 1.32,
  );

  static const spotify = Company(
    name: 'Spotify',
    ticker: 'SPOT',
    symbol: 'tSPOTc',
    description:
        'The company behind Spotify, Wrapped and the podcast catalogue.',
    products: ['Spotify', 'Wrapped', 'Podcasts'],
    price: 312.75,
    change: 3.08,
  );

  /// Ordered so the grid alternates light and dark tiles rather than clumping.
  static const trending = [
    nvidia,
    apple,
    meta,
    spotify,
    tesla,
    alphabet,
    microsoft,
    amazon,
  ];
}
