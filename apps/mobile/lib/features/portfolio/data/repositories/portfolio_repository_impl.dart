import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/portfolio/data/datasource/portfolio_local_datasource.dart';
import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';
import 'package:tickerless/features/portfolio/domain/repositories/portfolio_repository.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  const PortfolioRepositoryImpl({
    required PortfolioLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final PortfolioLocalDataSource _localDataSource;

  @override
  Future<List<OwnedPosition>> positions() async => _localDataSource.positions();

  @override
  Future<List<OwnedPosition>> record({
    required Company company,
    required double invested,
    required double tokens,
    required String source,
  }) async => _localDataSource.record(
    company: company,
    invested: invested,
    tokens: tokens,
    source: source,
  );
}
