import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/tickerless_wordmark.dart';
import 'package:tickerless/features/discovery/data/registry/demo_companies.dart';
import 'package:tickerless/features/discovery/domain/entities/discovery_source.dart';
import 'package:tickerless/features/home/presentation/widgets/entry_tile.dart';
import 'package:tickerless/features/home/presentation/widgets/portfolio_preview_card.dart';
import 'package:tickerless/features/home/presentation/widgets/trending_row.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_bloc.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_state.dart';

/// The front door: the three ways to discover something, what the user
/// already owns, and what other people are looking at.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const TickerlessWordmark(compact: true),
            IconButton.filledTonal(
              tooltip: 'Open profile',
              onPressed: () => context.push(AppRoutes.profile),
              icon: const Icon(Icons.person_outline),
            ),
          ],
        ),
        const SizedBox(height: 40),
        const Text(
          'What caught\nyour attention\ntoday?',
          style: TextStyle(
            fontSize: 40,
            height: 0.94,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.6,
          ),
        ),
        const SizedBox(height: 26),
        TextField(
          readOnly: true,
          onTap: () => context.push(AppRoutes.search),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search anything...',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: EntryTile(
                icon: Icons.center_focus_strong,
                label: 'Lens',
                onTap: () => context.push(AppRoutes.lens),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: EntryTile(
                icon: Icons.link,
                label: 'Link',
                onTap: () => context.push(AppRoutes.link),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: EntryTile(
                icon: Icons.search,
                label: 'Search',
                onTap: () => context.push(AppRoutes.search),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        BlocBuilder<PortfolioBloc, PortfolioState>(
          builder: (context, state) => switch (state) {
            PortfolioLoaded() => PortfolioPreviewCard(
              positions: state.positions,
              total: state.total,
              onTap: () => context.go(AppRoutes.world),
            ),
            _ => const SizedBox.shrink(),
          },
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.blue, size: 16),
            SizedBox(width: 8),
            Text(
              'Base Sepolia · Demo assets',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Text(
          'Things people are discovering',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...DemoCompanies.trending.map(
          (company) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: TrendingRow(
              company: company,
              onTap: () => context.push(
                AppRoutes.passport,
                extra: PassportArgs(
                  company: company,
                  source: DiscoverySource.trending.describe('Trending'),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
