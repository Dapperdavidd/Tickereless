import 'package:flutter_test/flutter_test.dart';
import 'package:tickerless/features/discovery/data/registry/demo_companies.dart';
import 'package:tickerless/features/portfolio/data/datasource/portfolio_local_datasource.dart';
import 'package:tickerless/features/portfolio/data/repositories/portfolio_repository_impl.dart';

void main() {
  test(
    'purchase records only confirmed ownership without seeded figures',
    () async {
      final repository = PortfolioRepositoryImpl(
        localDataSource: InMemoryPortfolioDataSource(),
      );

      final positions = await repository.record(
        company: DemoCompanies.meta,
        invested: 5,
        tokens: .01,
        source: 'Threads · Search',
      );

      final meta = positions.singleWhere(
        (position) => position.company.ticker == 'META',
      );
      expect(meta.invested, 5);
      expect(meta.tokens, .01);
      expect(meta.sources, contains('Threads · Search'));
      expect(
        positions.fold<double>(0, (sum, position) => sum + position.invested),
        5,
      );
    },
  );

  test('a first purchase opens a new position', () async {
    final repository = PortfolioRepositoryImpl(
      localDataSource: InMemoryPortfolioDataSource(),
    );

    final positions = await repository.record(
      company: DemoCompanies.alphabet,
      invested: 3,
      tokens: .02,
      source: 'YouTube · Lens',
    );

    final alphabet = positions.singleWhere(
      (position) => position.company.ticker == 'GOOGL',
    );
    expect(alphabet.invested, 3);
    expect(alphabet.sources, ['YouTube · Lens']);
  });
}
