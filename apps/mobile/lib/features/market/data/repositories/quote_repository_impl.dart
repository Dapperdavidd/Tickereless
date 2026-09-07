import 'package:tickerless/features/market/data/datasource/demo_series_datasource.dart';
import 'package:tickerless/features/market/domain/entities/chart_range.dart';
import 'package:tickerless/features/market/domain/entities/price_series.dart';
import 'package:tickerless/features/market/domain/repositories/quote_repository.dart';

/// Serves demo series until the backend grows a price-history endpoint.
///
/// When it does, only this class changes: swap the data source for an HTTP one
/// and flip `isDemo`. Nothing above it knows the difference.
class DemoQuoteRepository implements QuoteRepository {
  const DemoQuoteRepository({DemoSeriesDataSource? dataSource})
    : _dataSource = dataSource ?? const SeededDemoSeriesDataSource();

  final DemoSeriesDataSource _dataSource;

  @override
  Future<PriceSeries> series({
    required String ticker,
    required double anchorPrice,
    required ChartRange range,
  }) async => PriceSeries(
    range: range,
    values: _dataSource.walk(
      ticker: ticker,
      anchorPrice: anchorPrice,
      range: range,
    ),
    isDemo: true,
  );
}
