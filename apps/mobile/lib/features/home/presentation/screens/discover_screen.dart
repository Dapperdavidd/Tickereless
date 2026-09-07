import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/features/discovery/data/registry/demo_companies.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/discovery/domain/entities/discovery_source.dart';
import 'package:tickerless/features/home/presentation/widgets/discover_header.dart';
import 'package:tickerless/features/home/presentation/widgets/discovery_tile.dart';
import 'package:tickerless/features/home/presentation/widgets/lens_fab.dart';
import 'package:tickerless/features/home/presentation/widgets/section_bar.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_bloc.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_state.dart';

/// The front door.
///
/// Companies are the content, so they get the screen: an edge-to-edge
/// staggered grid under a single line of chrome. Lens, Link and Search live in
/// the header and the raised button rather than as three tiles competing with
/// the thing the user actually came to look at.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 96),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DiscoverHeader(
                onSearch: () => context.push(AppRoutes.search),
                onLink: () => context.push(AppRoutes.link),
                onProfile: () => context.push(AppRoutes.profile),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: BlocBuilder<PortfolioBloc, PortfolioState>(
                builder: (context, state) => SectionBar(
                  title: 'Featured',
                  trailing: switch (state) {
                    PortfolioLoaded() =>
                      'Your World · \$${state.total.toStringAsFixed(2)}',
                    _ => 'Your World',
                  },
                  onTrailingTap: () => context.go(AppRoutes.world),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 228,
              child: DiscoveryTile(
                company: DemoCompanies.nvidia,
                onTap: () => _openPassport(context, DemoCompanies.nvidia),
              ),
            ),
            const SizedBox(height: 26),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Text(
                    'Across your world',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.5,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Swipe →',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            SizedBox(
              height: 178,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: DemoCompanies.trending.length - 1,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  final company = DemoCompanies.trending[index + 1];
                  return SizedBox(
                    width: 154,
                    child: DiscoveryTile(
                      company: company,
                      onTap: () => _openPassport(context, company),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
            const _DemoFootnote(),
          ],
        ),
      ),
      Positioned(
        right: 20,
        bottom: 24,
        child: LensFab(onTap: () => context.push(AppRoutes.lens)),
      ),
    ],
  );

  void _openPassport(BuildContext context, Company company) => context.push(
    AppRoutes.passport,
    extra: PassportArgs(
      company: company,
      source: DiscoverySource.trending.describe('Trending'),
    ),
  );
}

class _DemoFootnote extends StatelessWidget {
  const _DemoFootnote();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.check_circle, color: AppColors.blue, size: 13),
      SizedBox(width: 6),
      Text(
        'Base Sepolia · Demo assets',
        style: TextStyle(color: AppColors.muted, fontSize: 11),
      ),
    ],
  );
}
