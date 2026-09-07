/// The windows the passport chart can show.
enum ChartRange {
  hour('1H', 60),
  fourHours('4H', 96),
  day('1D', 120),
  week('1W', 168),
  month('1M', 180);

  const ChartRange(this.label, this.resolution);

  final String label;

  /// How many points the window is drawn from. Enough to look like tick data
  /// at every width, few enough to paint in one frame.
  final int resolution;
}
