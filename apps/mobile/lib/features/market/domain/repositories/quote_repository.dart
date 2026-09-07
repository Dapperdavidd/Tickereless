import 'package:tickerless/features/market/domain/entities/chart_range.dart';
import 'package:tickerless/features/market/domain/entities/price_series.dart';

abstract class QuoteRepository {
  /// The price history for a company over [range].
  ///
  /// [anchorPrice] is the company's current price, so a series always ends
  /// where the rest of the screen says the price is.
  Future<PriceSeries> series({
    required String ticker,
    required double anchorPrice,
    required ChartRange range,
  });
}
