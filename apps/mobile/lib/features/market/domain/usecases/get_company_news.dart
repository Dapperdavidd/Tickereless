import 'package:tickerless/features/market/domain/entities/news_article.dart';
import 'package:tickerless/features/market/domain/repositories/news_repository.dart';

class GetCompanyNewsUseCase {
  const GetCompanyNewsUseCase({required NewsRepository repository})
    : _repository = repository;

  final NewsRepository _repository;

  Future<List<NewsArticle>> call(String ticker) =>
      _repository.forCompany(ticker);
}
