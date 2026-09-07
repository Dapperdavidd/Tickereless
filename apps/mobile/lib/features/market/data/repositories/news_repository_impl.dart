import 'package:tickerless/features/market/domain/entities/news_article.dart';
import 'package:tickerless/features/market/domain/repositories/news_repository.dart';

/// There is no news feed yet — the backend exposes a resolver and a purchase
/// quote, nothing else.
///
/// This returns nothing rather than shipping invented headlines: fabricated
/// coverage about real public companies is the one kind of placeholder that
/// does damage if anyone screenshots it. The News tab renders an honest empty
/// state, and wiring a real feed means replacing this class alone.
class EmptyNewsRepository implements NewsRepository {
  const EmptyNewsRepository();

  @override
  Future<List<NewsArticle>> forCompany(String ticker) async => const [];
}
