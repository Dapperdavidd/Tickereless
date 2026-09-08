import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/features/market/domain/entities/chart_range.dart';
import 'package:tickerless/features/market/domain/entities/price_series.dart';
import 'package:tickerless/features/market/presentation/widgets/price_chart.dart';

class CurrencyAssetScreen extends StatelessWidget {
  const CurrencyAssetScreen({required this.args, super.key});
  final CurrencyAssetArgs args;

  @override
  Widget build(BuildContext context) {
    final isUsdc = args.symbol == 'USDC';
    final name = isUsdc ? 'USD Coin' : 'Base Sepolia ETH';
    final color = isUsdc ? const Color(0xFF2775CA) : const Color(0xFF235BFF);
    final series = PriceSeries(
      range: ChartRange.day,
      values: isUsdc
          ? const [1, 1, 1, 1, 1, 1, 1]
          : const [.92, .96, .94, 1.01, .98, 1.04, 1.02],
      isDemo: true,
    );
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: isUsdc
                ? const Text(
                    r'$ ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  )
                : const Icon(Icons.diamond_outlined, color: Colors.white),
          ),
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
          PriceChart(series: series, color: color, height: 210),
          Text(
            isUsdc
                ? 'USDC targets a stable \$1 reference value. This line is descriptive, not a live exchange feed.'
                : 'Illustrative testnet activity · not a live ETH market price',
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
