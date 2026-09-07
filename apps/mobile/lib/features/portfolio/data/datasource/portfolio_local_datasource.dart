import 'package:tickerless/features/discovery/data/registry/demo_companies.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';

/// Holdings for the demo, kept in memory for the life of the process.
///
/// Swapping this for a device-backed or on-chain source is a one-file change:
/// nothing above it knows where positions come from.
abstract interface class PortfolioLocalDataSource {
  List<OwnedPosition> positions();
  List<OwnedPosition> record({
    required Company company,
    required double invested,
    required double tokens,
    required String source,
  });
}

class InMemoryPortfolioDataSource implements PortfolioLocalDataSource {
  InMemoryPortfolioDataSource({Map<String, OwnedPosition>? seed})
    : _positions = seed ?? _demoSeed();

  final Map<String, OwnedPosition> _positions;

  @override
  List<OwnedPosition> positions() => List.unmodifiable(_positions.values);

  @override
  List<OwnedPosition> record({
    required Company company,
    required double invested,
    required double tokens,
    required String source,
  }) {
    final current = _positions[company.ticker];
    _positions[company.ticker] =
        current?.merge(invested: invested, tokens: tokens, source: source) ??
        OwnedPosition(
          company: company,
          invested: invested,
          tokens: tokens,
          sources: [source],
        );
    return positions();
  }

  static Map<String, OwnedPosition> _demoSeed() => {
    'AAPL': OwnedPosition(
      company: DemoCompanies.apple,
      invested: 14,
      tokens: 14 / DemoCompanies.apple.price,
      sources: const ['iPhone · Lens'],
    ),
    'NVDA': OwnedPosition(
      company: DemoCompanies.nvidia,
      invested: 8,
      tokens: 8 / DemoCompanies.nvidia.price,
      sources: const ['AI article · Link'],
    ),
    'META': const OwnedPosition(
      company: DemoCompanies.meta,
      invested: 5,
      tokens: .01,
      sources: ['Instagram · Search'],
    ),
  };
}
