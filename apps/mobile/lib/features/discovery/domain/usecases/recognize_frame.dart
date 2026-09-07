import 'package:tickerless/features/discovery/domain/entities/company_match.dart';
import 'package:tickerless/features/discovery/domain/repositories/discovery_repository.dart';

class RecognizeFrameUseCase {
  const RecognizeFrameUseCase({required DiscoveryRepository repository})
    : _repository = repository;

  final DiscoveryRepository _repository;

  Future<List<CompanyMatch>> call(String imagePath) =>
      _repository.recognizeFrame(imagePath);
}
