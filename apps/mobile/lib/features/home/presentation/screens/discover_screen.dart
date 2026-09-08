import 'dart:async';

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
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late final PageController _worldController = PageController(
    viewportFraction: .58,
  );
  Timer? _worldTimer;

  @override
  void initState() {
    super.initState();
    _worldTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_worldController.hasClients) return;
      final current = _worldController.page?.round() ?? 0;
      _worldController.animateToPage(
        (current + 1) % (DemoCompanies.trending.length - 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _worldTimer?.cancel();
    _worldController.dispose();
    super.dispose();
  }

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
                      'Your Assets · \$${state.total.toStringAsFixed(2)}',
                    _ => 'Your Assets',
                  },
                  onTrailingTap: () => context.go(AppRoutes.activity),
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
                    'Moving with the market',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            SizedBox(
              height: 270,
              child: PageView.builder(
                controller: _worldController,
                scrollDirection: Axis.vertical,
                itemCount: DemoCompanies.trending.length - 1,
                itemBuilder: (context, index) {
                  final company = DemoCompanies.trending[index + 1];
                  return AnimatedBuilder(
                    animation: _worldController,
                    builder: (context, child) {
                      final page = _worldController.hasClients
                          ? (_worldController.page ?? 0)
                          : 0.0;
                      final distance = (page - index).abs().clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: 1 - distance * .08,
                        child: Opacity(
                          opacity: 1 - distance * .38,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: DiscoveryTile(
                        company: company,
                        onTap: () => _openPassport(context, company),
                      ),
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
        'Base Sepolia · Live testnet',
        style: TextStyle(color: AppColors.muted, fontSize: 11),
      ),
    ],
  );
}
