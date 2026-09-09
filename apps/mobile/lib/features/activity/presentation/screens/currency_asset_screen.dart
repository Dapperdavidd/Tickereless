import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/features/market/domain/entities/chart_range.dart';
import 'package:tickerless/features/market/domain/entities/price_series.dart';
import 'package:tickerless/features/market/presentation/widgets/price_chart.dart';
import 'package:tickerless/features/wallet/presentation/widgets/token_logo.dart';

class CurrencyAssetScreen extends StatelessWidget {
  const CurrencyAssetScreen({required this.args, super.key});
  final CurrencyAssetArgs args;

  @override
  Widget build(BuildContext context) {
    final isUsdc = args.symbol == 'USDC';
    final name = isUsdc ? 'USD Coin' : 'Base Sepolia ETH';
    final color = isUsdc ? const Color(0xFF2775CA) : const Color(0xFF235BFF);
    final usdcReference = PriceSeries(
      range: ChartRange.day,
      values: const [1, 1, 1, 1, 1, 1, 1],
      isDemo: true,
    );
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          TokenLogo(symbol: args.symbol, size: 56),
          const SizedBox(height: 18),
          Text(
            isUsdc
                ? '\$${args.balance.toStringAsFixed(2)}'
                : '${args.balance.toStringAsFixed(6)} ETH',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$name · Base Sepolia',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 22),
          if (isUsdc)
            PriceChart(series: usdcReference, color: color, height: 210)
          else
            const _LiveChartUnavailable(),
          Text(
            isUsdc
                ? 'Stable \$1 reference · descriptive, not a live exchange feed'
                : 'No synthetic price movement is shown.',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.activity),
                  icon: const Icon(Icons.arrow_upward_rounded),
                  label: const Text('Send'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.activity),
                  icon: const Icon(Icons.arrow_downward_rounded),
                  label: const Text('Receive'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Network', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 5),
          const Text('Base Sepolia testnet'),
          const SizedBox(height: 16),
          const Text('Purpose', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 5),
          Text(
            isUsdc ? 'Settlement and purchasing' : 'Network transaction fees',
          ),
        ],
      ),
    );
  }
}

class _LiveChartUnavailable extends StatelessWidget {
  const _LiveChartUnavailable();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Live Base Sepolia ETH chart unavailable',
    child: Container(
      height: 210,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.query_stats_rounded, color: AppColors.muted),
              SizedBox(height: 10),
              Text(
                'Live market chart unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 5),
              Text(
                'Connect a verified ETH price-history feed to display real movement.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
