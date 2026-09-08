import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tickerless/features/market/data/repositories/news_repository_impl.dart';

void main() {
  test(
    'official newsroom feed becomes chronological company coverage',
    () async {
      final repository = OfficialNewsRepository(
        client: MockClient(
          (_) async =>
              http.Response('''<?xml version="1.0"?><rss><channel><item>
          <title>Apple introduces something new</title>
          <link>https://www.apple.com/newsroom/example</link>
          <pubDate>Mon, 07 Sep 2026 10:00:00 GMT</pubDate>
          </item></channel></rss>''', 200),
        ),
      );

      final articles = await repository.forCompany('AAPL');

      expect(articles.single.headline, 'Apple introduces something new');
      expect(articles.single.source, 'Apple Newsroom');
      expect(articles.single.publishedAt, DateTime.utc(2026, 9, 7, 10));
      expect(articles.single.url, 'https://www.apple.com/newsroom/example');
    },
  );

  test('unsupported companies do not make a network request', () async {
    final repository = OfficialNewsRepository(
      client: MockClient((_) async => throw StateError('should not fetch')),
    );

    expect(await repository.forCompany('UNKNOWN'), isEmpty);
  });

  test('missing publisher dates are not presented as breaking news', () async {
    final repository = OfficialNewsRepository(
      client: MockClient(
        (_) async => http.Response(
          '<rss><channel><item><title>Undated</title><link>https://example.com</link></item></channel></rss>',
          200,
        ),
      ),
    );

    expect(await repository.forCompany('AAPL'), isEmpty);
  });
}
