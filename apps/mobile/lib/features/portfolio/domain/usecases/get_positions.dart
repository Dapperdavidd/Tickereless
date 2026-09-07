import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';
import 'package:tickerless/features/portfolio/domain/repositories/portfolio_repository.dart';

class GetPositionsUseCase {
  const GetPositionsUseCase({required PortfolioRepository repository})
    : _repository = repository;

  final PortfolioRepository _repository;

  Future<List<OwnedPosition>> call() => _repository.positions();
}
