import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/glass_card.dart';
import 'package:tickerless/core/widgets/summary_row.dart';

/// The receipt. Both ways out lead back into the app, not back through the
/// purchase flow the user just finished.
class PurchaseConfirmedScreen extends StatelessWidget {
  const PurchaseConfirmedScreen({required this.args, super.key});

  final ReceiptArgs args;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              child: Icon(Icons.check, color: Colors.black, size: 42),
            ),
            const SizedBox(height: 28),
            Text(
              'You now own\n${args.company.name}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\$${args.invested.toStringAsFixed(0)} · '
              '${args.tokens.toStringAsFixed(4)} ${args.company.symbol}',
              style: const TextStyle(fontSize: 18),
            ),
            const Text(
              'on Base Sepolia',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            GlassCard(
              child: Column(
                children: [
                  SummaryRow(label: 'Discovered via', value: args.source),
                  const SizedBox(height: 14),
                  const SummaryRow(
                    label: 'Transaction',
                    value: 'View on BaseScan ↗',
                  ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go(AppRoutes.world),
              child: const Text('View in Your World'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.discover),
              child: const Text('Make Another Discovery'),
            ),
          ],
        ),
      ),
    ),
  );
}
