import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';
import 'package:tickerless/features/portfolio/domain/repositories/portfolio_repository.dart';

class RecordPurchaseUseCase {
  const RecordPurchaseUseCase({required PortfolioRepository repository})
    : _repository = repository;

  final PortfolioRepository _repository;

  Future<List<OwnedPosition>> call({
    required Company company,
    required double invested,
    required double tokens,
    required String source,
  }) => _repository.record(
    company: company,
    invested: invested,
    tokens: tokens,
    source: source,
  );
}
