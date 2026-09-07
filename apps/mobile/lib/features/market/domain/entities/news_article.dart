import 'package:equatable/equatable.dart';

/// A piece of coverage about a company.
class NewsArticle extends Equatable {
  const NewsArticle({
    required this.headline,
    required this.source,
    required this.publishedAt,
    required this.url,
  });

  final String headline;
  final String source;
  final DateTime publishedAt;
  final String url;

  @override
  List<Object?> get props => [headline, source, publishedAt, url];
}
