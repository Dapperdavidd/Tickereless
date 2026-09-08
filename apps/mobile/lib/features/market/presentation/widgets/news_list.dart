import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/features/market/domain/entities/news_article.dart';
import 'package:url_launcher/url_launcher.dart';

/// Coverage for a company, as plain rows.
class NewsList extends StatelessWidget {
  const NewsList({required this.articles, super.key});

  final List<NewsArticle> articles;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const _NoCoverage();

    return Column(
      children: [
        for (final (index, article) in articles.indexed) ...[
          if (index > 0) const Divider(height: 26, color: AppColors.border),
          _ArticleRow(article: article),
        ],
      ],
    );
  }
}

/// Says plainly that there is no feed, rather than filling the tab with
/// invented headlines about a real public company.
class _NoCoverage extends StatelessWidget {
  const _NoCoverage();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No coverage yet',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        SizedBox(height: 6),
        Text(
          'Tickerless does not index news for this company yet. When a feed is '
          'connected, stories about the products you discovered show up here.',
          style: TextStyle(color: AppColors.muted, height: 1.5, fontSize: 13),
        ),
      ],
    ),
  );
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.article});

  final NewsArticle article;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(article.url);
    final opened =
        uri != null && await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This article could not be opened.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _open(context),
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.headline,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${article.source} · ${_ago(article.publishedAt)}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.north_east_rounded,
            size: 15,
            color: AppColors.muted,
          ),
        ],
      ),
    ),
  );

  static String _ago(DateTime published) {
    final elapsed = DateTime.now().difference(published);
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    return '${elapsed.inDays}d ago';
  }
}
