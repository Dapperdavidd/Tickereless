import 'package:equatable/equatable.dart';
import 'package:tickerless/features/market/domain/entities/chart_range.dart';

/// A company's price over one window.
class PriceSeries extends Equatable {
  const PriceSeries({
    required this.range,
    required this.values,
    required this.isDemo,
  });

  final ChartRange range;

  /// Oldest first. Plain doubles rather than timestamped points: the chart
  /// plots evenly spaced samples, so a time on each one would be carried
  /// around unused.
  final List<double> values;

  /// True when these numbers did not come from a market — the app says so
  /// on screen rather than letting a drawn line imply a feed exists.
  final bool isDemo;

  double get open => values.first;
  double get close => values.last;
  double get low => values.reduce((a, b) => a < b ? a : b);
  double get high => values.reduce((a, b) => a > b ? a : b);

  /// Percentage move across the window.
  double get change => open == 0 ? 0 : (close - open) / open * 100;

  bool get isUp => close >= open;

  @override
  List<Object?> get props => [range, values, isDemo];
}
