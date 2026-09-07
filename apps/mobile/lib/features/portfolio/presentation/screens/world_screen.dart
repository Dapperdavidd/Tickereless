import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/features/discovery/data/registry/demo_companies.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/discovery/presentation/widgets/company_logo.dart';
import 'package:tickerless/features/market/domain/entities/news_article.dart';
import 'package:tickerless/features/market/domain/usecases/get_company_news.dart';
import 'package:url_launcher/url_launcher.dart';

class WorldScreen extends StatefulWidget {
  const WorldScreen({super.key});
  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  static const _companies = [
    DemoCompanies.apple,
    DemoCompanies.nvidia,
    DemoCompanies.meta,
    DemoCompanies.alphabet,
    DemoCompanies.tesla,
    DemoCompanies.spotify,
    DemoCompanies.amazon,
    DemoCompanies.microsoft,
  ];
  final _searchController = TextEditingController();
  String _query = '';
  late Future<List<_CompanyStory>> _stories;

  @override
  void initState() {
    super.initState();
    _stories = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<_CompanyStory>> _load() async {
    final news = context.read<GetCompanyNewsUseCase>();
    final groups = await Future.wait(
      _companies.map((company) async {
        try {
          return [
            for (final article in await news(company.ticker))
              _CompanyStory(company: company, article: article),
          ];
        } catch (_) {
          return <_CompanyStory>[];
        }
      }),
    );
    return groups.expand((group) => group).toList()
      ..sort((a, b) => b.article.publishedAt.compareTo(a.article.publishedAt));
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _stories = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FutureBuilder<List<_CompanyStory>>(
      future: _stories,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <_CompanyStory>[];
        final needle = _query.trim().toLowerCase();
        final visible = needle.isEmpty
            ? all
            : all.where((story) {
                final searchable =
                    '${story.company.name} ${story.company.ticker} ${story.article.headline} ${story.article.source}'
                        .toLowerCase();
                return searchable.contains(needle);
              }).toList();
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            children: [
              const Text(
                'World',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'What is moving the companies behind your world.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search company or news…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _NewsSkeleton()
              else if (visible.isEmpty)
                _EmptyNews(onRetry: _refresh)
              else ...[
                _LeadStory(story: visible.first),
                const SizedBox(height: 30),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Latest',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${visible.length} stories',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final story in visible.skip(1)) _StoryRow(story: story),
              ],
              const SizedBox(height: 22),
              const Text(
                'Coverage comes directly from official company newsrooms.',
                style: TextStyle(color: AppColors.muted, fontSize: 10.5),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _CompanyStory {
  const _CompanyStory({required this.company, required this.article});
  final Company company;
  final NewsArticle article;
}

class _LeadStory extends StatelessWidget {
  const _LeadStory({required this.story});
  final _CompanyStory story;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => launchUrl(
      Uri.parse(story.article.url),
      mode: LaunchMode.externalApplication,
    ),
    borderRadius: BorderRadius.circular(24),
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CompanyLogo(
                ticker: story.company.ticker,
                size: 28,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                '${story.company.name} · ${story.company.ticker}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const Spacer(),
              const Icon(Icons.north_east_rounded, size: 17),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            story.article.headline,
            style: const TextStyle(
              fontSize: 25,
              height: 1.08,
              fontWeight: FontWeight.w700,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${story.article.source} · ${_ago(story.article.publishedAt)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _StoryRow extends StatelessWidget {
  const _StoryRow({required this.story});
  final _CompanyStory story;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => launchUrl(
      Uri.parse(story.article.url),
      mode: LaunchMode.externalApplication,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: CompanyLogo(
              ticker: story.company.ticker,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.article.headline,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${story.company.ticker} · ${story.article.source} · ${_ago(story.article.publishedAt)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.muted,
          ),
        ],
      ),
    ),
  );
}

class _EmptyNews extends StatelessWidget {
  const _EmptyNews({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70),
    child: Column(
      children: [
        const Icon(Icons.public_rounded, size: 40),
        const SizedBox(height: 16),
        const Text(
          'The newsroom is quiet right now.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pull to refresh or try again.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}

String _ago(DateTime published) {
  final elapsed = DateTime.now().difference(published);
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes.clamp(0, 59)}m ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
  return '${elapsed.inDays}d ago';
}

class _NewsSkeleton extends StatefulWidget {
  const _NewsSkeleton();
  @override
  State<_NewsSkeleton> createState() => _NewsSkeletonState();
}

class _NewsSkeletonState extends State<_NewsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final pulse = _controller.value < .5
          ? _controller.value
          : 1 - _controller.value;
      final color = Colors.white.withValues(alpha: .06 + pulse * .18);
      Widget bar(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 210,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(110, 14),
                const Spacer(),
                bar(double.infinity, 24),
                const SizedBox(height: 10),
                bar(240, 24),
                const SizedBox(height: 18),
                bar(130, 12),
              ],
            ),
          ),
          const SizedBox(height: 30),
          bar(80, 18),
          const SizedBox(height: 22),
          for (var index = 0; index < 3; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  bar(30, 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(double.infinity, 15),
                        const SizedBox(height: 8),
                        bar(180, 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}
