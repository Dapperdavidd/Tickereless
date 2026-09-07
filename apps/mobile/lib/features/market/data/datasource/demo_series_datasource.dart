import 'dart:math';

import 'package:tickerless/features/market/domain/entities/chart_range.dart';

/// Stands in for a price feed the backend does not have yet.
///
/// The walk is seeded from the ticker and the range, so a company's 1D chart
/// is the same line every time the screen opens — a chart that reshuffles on
/// each visit reads as broken, and would also hide real changes once a feed
/// replaces this. Volatility scales with the window so 1H looks like intraday
/// noise and 1M looks like a trend.
abstract interface class DemoSeriesDataSource {
  List<double> walk({
    required String ticker,
    required double anchorPrice,
    required ChartRange range,
  });
}

class SeededDemoSeriesDataSource implements DemoSeriesDataSource {
  const SeededDemoSeriesDataSource();

  @override
  List<double> walk({
    required String ticker,
    required double anchorPrice,
    required ChartRange range,
  }) {
    final random = Random(ticker.hashCode ^ (range.index * 7919));
    final volatility = switch (range) {
      ChartRange.hour => .0016,
      ChartRange.fourHours => .0028,
      ChartRange.day => .0042,
      ChartRange.week => .0065,
      ChartRange.month => .009,
    };
    // A slight drift keeps the line from wandering back to where it started
    // on every window, which is what makes a random walk look synthetic.
    final drift = (random.nextDouble() - .42) * volatility * .5;

    final values = <double>[];
    var price = anchorPrice * (1 - (random.nextDouble() * .06 - .02));
    for (var index = 0; index < range.resolution; index++) {
      price *= 1 + drift + (random.nextDouble() - .5) * volatility * 2;
      values.add(price);
    }

    // The series has to land on the price the rest of the screen shows, so
    // the walk is scaled to end exactly there.
    final correction = anchorPrice / values.last;
    return [
      for (final (index, value) in values.indexed)
        value * (1 + (correction - 1) * (index / (values.length - 1))),
    ];
  }
}
