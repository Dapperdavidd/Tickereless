import 'package:flutter_test/flutter_test.dart';
import 'package:tickerless/features/discovery/data/registry/demo_companies.dart';
import 'package:tickerless/features/portfolio/data/datasource/portfolio_local_datasource.dart';
import 'package:tickerless/features/portfolio/data/repositories/portfolio_repository_impl.dart';

void main() {
  test('purchase aggregates ownership and discovery context', () async {
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
    expect(meta.invested, 10);
    expect(meta.tokens, .02);
    expect(meta.sources, contains('Threads · Search'));
    expect(meta.sources, contains('Instagram · Search'));
    expect(
      positions.fold<double>(0, (sum, position) => sum + position.invested),
      32,
    );
  });

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
