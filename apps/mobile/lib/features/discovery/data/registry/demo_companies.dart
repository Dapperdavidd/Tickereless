import 'package:tickerless/features/discovery/domain/entities/company.dart';

/// Local company fallbacks used while the live resolver is loading.
///
/// Prices are cached indications only. The API supplies live issuer prices.
abstract final class DemoCompanies {
  static const apple = Company(
    name: 'Apple',
    ticker: 'AAPL',
    symbol: 'AAPLx',
    description: 'The company behind iPhone, Mac, iPad, AirPods and more.',
    products: ['iPhone', 'Mac', 'AirPods'],
    price: 331.46,
    change: 1.81,
  );

  static const meta = Company(
    name: 'Meta Platforms',
    ticker: 'META',
    symbol: 'METAx',
    description:
        'The parent company of Instagram, WhatsApp, Facebook and Threads.',
    products: ['Instagram', 'WhatsApp', 'Threads'],
    price: 730.375,
    change: 1.2,
  );

  static const nvidia = Company(
    name: 'NVIDIA',
    ticker: 'NVDA',
    symbol: 'NVDAx',
    description:
        'The computing company behind GeForce, RTX, CUDA and accelerated AI.',
    products: ['GeForce', 'RTX', 'CUDA'],
    price: 232.885,
    change: 2.4,
  );

  static const alphabet = Company(
    name: 'Alphabet',
    ticker: 'GOOGL',
    symbol: 'GOOGLx',
    description:
        'The company behind Google Search, YouTube, Android, Gemini and more.',
    products: ['Google', 'YouTube', 'Gemini'],
    price: 341.115,
    change: 1.09,
  );

  static const tesla = Company(
    name: 'Tesla',
    ticker: 'TSLA',
    symbol: 'TSLAx',
    description:
        'The company behind Model 3, Model Y, Powerwall and the Supercharger network.',
    products: ['Model Y', 'Powerwall', 'Supercharger'],
    price: 357.78,
    change: 2.94,
  );

  static const microsoft = Company(
    name: 'Microsoft',
    ticker: 'MSFT',
    symbol: 'MSFTx',
    description: 'The company behind Windows, Office, Xbox, Azure and Copilot.',
    products: ['Windows', 'Xbox', 'Azure'],
    price: 516.89,
    change: .74,
  );

  static const amazon = Company(
    name: 'Amazon',
    ticker: 'AMZN',
    symbol: 'AMZNx',
    description: 'The company behind Amazon, Prime, Kindle, Alexa and AWS.',
    products: ['Prime', 'Kindle', 'AWS'],
    price: 249.751,
    change: 1.32,
  );

  static const spotify = Company(
    name: 'Spotify',
    ticker: 'SPOT',
    symbol: 'SPOT',
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
