import 'package:tickerless/features/market/domain/entities/chart_range.dart';
import 'package:tickerless/features/market/domain/entities/price_series.dart';
import 'package:tickerless/features/market/domain/repositories/quote_repository.dart';

class GetPriceSeriesUseCase {
  const GetPriceSeriesUseCase({required QuoteRepository repository})
    : _repository = repository;

  final QuoteRepository _repository;

  Future<PriceSeries> call({
    required String ticker,
    required double anchorPrice,
    required ChartRange range,
  }) => _repository.series(
    ticker: ticker,
    anchorPrice: anchorPrice,
    range: range,
  );
}
