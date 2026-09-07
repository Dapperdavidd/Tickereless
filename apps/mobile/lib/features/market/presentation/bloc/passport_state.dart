import 'package:equatable/equatable.dart';
import 'package:tickerless/features/market/domain/entities/chart_range.dart';
import 'package:tickerless/features/market/domain/entities/news_article.dart';
import 'package:tickerless/features/market/domain/entities/price_series.dart';

class PassportState extends Equatable {
  const PassportState({
    this.range = ChartRange.day,
    this.series,
    this.articles = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final ChartRange range;

  /// Null until the first window has loaded.
  final PriceSeries? series;
  final List<NewsArticle> articles;
  final bool isLoading;
  final String? errorMessage;

  PassportState copyWith({
    ChartRange? range,
    PriceSeries? series,
    List<NewsArticle>? articles,
    bool? isLoading,
    String? errorMessage,
  }) => PassportState(
    range: range ?? this.range,
    series: series ?? this.series,
    articles: articles ?? this.articles,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [range, series, articles, isLoading, errorMessage];
}
