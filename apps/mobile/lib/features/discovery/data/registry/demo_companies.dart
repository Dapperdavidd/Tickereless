import 'package:tickerless/features/discovery/domain/entities/company.dart';

/// The companies the demo ships with — what Discover trends and what the
/// screens fall back to before the resolver has answered.
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

  static const trending = [apple, nvidia, meta, alphabet];
}
