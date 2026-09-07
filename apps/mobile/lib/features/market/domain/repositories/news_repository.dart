import 'package:tickerless/features/market/domain/entities/news_article.dart';

abstract class NewsRepository {
  /// Coverage for a company, newest first. Empty when there is no feed.
  Future<List<NewsArticle>> forCompany(String ticker);
}
