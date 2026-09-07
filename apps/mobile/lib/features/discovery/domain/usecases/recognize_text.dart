import 'package:tickerless/features/discovery/domain/entities/company_match.dart';
import 'package:tickerless/features/discovery/domain/repositories/discovery_repository.dart';

class RecognizeTextUseCase {
  const RecognizeTextUseCase({required DiscoveryRepository repository})
    : _repository = repository;

  final DiscoveryRepository _repository;

  Future<List<CompanyMatch>> call(
    String text, {
    List<String> labels = const [],
  }) => _repository.recognizeText(text, labels: labels);
}
