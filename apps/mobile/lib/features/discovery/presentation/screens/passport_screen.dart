import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/glass_card.dart';
import 'package:tickerless/core/widgets/pill.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_state.dart';
import 'package:tickerless/features/discovery/presentation/brand_palette.dart';
import 'package:tickerless/features/discovery/presentation/widgets/company_avatar.dart';

/// Everything known about one company, and the way to own a piece of it.
class PassportScreen extends StatelessWidget {
  const PassportScreen({required this.args, super.key});

  final PassportArgs args;

  /// Guests get this far on purpose: discovery is open, ownership is not.
  void _own(BuildContext context) {
    if (context.read<AuthBloc>().state.canPurchase) {
      context.push(
        AppRoutes.purchase,
        extra: PurchaseArgs(company: args.company, source: args.source),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.lock_outline_rounded),
        title: const Text('Sign in to own a piece'),
        content: const Text(
          'Guests can discover, scan, search, and explore. Create or sign in '
          'to an account before purchasing test assets.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push(AppRoutes.emailAuth);
            },
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = args.company;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Company Passport',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.ios_share_outlined),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Container(
            height: 185,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  BrandPalette.colorFor(company.ticker).withValues(alpha: .18),
                  AppColors.background,
                ],
              ),
            ),
            child: Center(child: CompanyAvatar(company: company, radius: 52)),
          ),
          const SizedBox(height: 16),
          Text(
            company.name,
            style: const TextStyle(
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${company.ticker}c  ·  Base Sepolia',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            company.description,
            style: const TextStyle(height: 1.45, color: Color(0xFFD4DEE3)),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: company.products.map(Pill.new).toList()),
          const SizedBox(height: 14),
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${company.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '+${company.change}% today',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  width: 100,
                  child: Icon(
                    Icons.show_chart,
                    color: AppColors.green,
                    size: 52,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (previous, current) => previous.mode != current.mode,
            builder: (context, _) => FilledButton(
              onPressed: () => _own(context),
              child: Text('Own ${company.name}'),
            ),
          ),
          const SizedBox(height: 22),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PassportTab('About', selected: true),
              _PassportTab('Products'),
              _PassportTab('News'),
            ],
          ),
          const Divider(height: 20),
          const Text(
            'Discovered through',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.travel_explore, color: AppColors.blue),
                const SizedBox(width: 12),
                Expanded(child: Text(args.source)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassportTab extends StatelessWidget {
  const _PassportTab(this.label, {this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: selected ? Colors.white : AppColors.muted,
      fontSize: 12,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
    ),
  );
}
