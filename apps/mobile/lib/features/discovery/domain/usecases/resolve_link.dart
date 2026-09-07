import 'package:tickerless/features/discovery/domain/entities/company_match.dart';
import 'package:tickerless/features/discovery/domain/repositories/discovery_repository.dart';

class ResolveLinkUseCase {
  const ResolveLinkUseCase({required DiscoveryRepository repository})
    : _repository = repository;

  final DiscoveryRepository _repository;

  Future<List<CompanyMatch>> call(String url) =>
      _repository.resolveLink(url.trim());
}
