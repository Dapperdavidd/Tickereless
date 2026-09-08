import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tickerless/features/market/domain/entities/news_article.dart';
import 'package:tickerless/features/market/domain/repositories/news_repository.dart';
import 'package:xml/xml.dart';

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

/// Reads each supported company's own newsroom feed. This keeps the hub current
/// without inventing headlines or requiring a third-party API key.
class OfficialNewsRepository implements NewsRepository {
  OfficialNewsRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _feeds = {
    'AAPL': 'https://www.apple.com/newsroom/rss-feed.rss',
    'NVDA': 'https://blogs.nvidia.com/feed/',
    'META': 'https://about.fb.com/news/feed/',
    'GOOGL': 'https://blog.google/rss/',
    'TSLA':
        'https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=1318605&type=8-K&output=atom',
    'SPOT': 'https://newsroom.spotify.com/feed/',
    'AMZN': 'https://www.aboutamazon.com/news/rss',
    'MSFT': 'https://blogs.microsoft.com/feed/',
  };

  @override
  Future<List<NewsArticle>> forCompany(String ticker) async {
    final feed = _feeds[ticker];
    if (feed == null) return const [];
    final response = await _client
        .get(
          Uri.parse(feed),
          headers: const {'user-agent': 'Tickerless demo app'},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('News is temporarily unavailable.');
    }
    final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
    final entries = document.findAllElements('item').isNotEmpty
        ? document.findAllElements('item')
        : document.findAllElements('entry');
    return entries
        .take(8)
        .map((item) {
          final title =
              item.getElement('title')?.innerText.trim() ?? 'Untitled';
          final link = item.getElement('link');
          final url =
              link?.getAttribute('href') ?? link?.innerText.trim() ?? feed;
          final published =
              item.getElement('pubDate')?.innerText.trim() ??
              item.getElement('updated')?.innerText.trim();
          final publishedAt = _publishedAt(published);
          if (publishedAt == null) return null;
          return NewsArticle(
            headline: title,
            source: _sourceName(ticker),
            publishedAt: publishedAt,
            url: url,
          );
        })
        .whereType<NewsArticle>()
        .toList(growable: false);
  }

  static String _sourceName(String ticker) => switch (ticker) {
    'AAPL' => 'Apple Newsroom',
    'NVDA' => 'NVIDIA Blog',
    'META' => 'Meta Newsroom',
    'GOOGL' => 'Google Blog',
    'TSLA' => 'SEC filings',
    'SPOT' => 'Spotify Newsroom',
    'AMZN' => 'Amazon News',
    'MSFT' => 'Microsoft Blog',
    _ => ticker,
  };

  static DateTime? _publishedAt(String? value) {
    if (value == null) return null;
    try {
      return HttpDate.parse(value);
    } catch (_) {
      return DateTime.tryParse(value);
    }
  }
}
