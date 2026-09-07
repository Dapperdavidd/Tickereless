import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';

abstract class PortfolioRepository {
  Future<List<OwnedPosition>> positions();

  /// Records a purchase, merging into any position already held.
  Future<List<OwnedPosition>> record({
    required Company company,
    required double invested,
    required double tokens,
    required String source,
  });
}
