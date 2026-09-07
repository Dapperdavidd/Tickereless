import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/flow_scaffold.dart';
import 'package:tickerless/core/widgets/hairline_list.dart';
import 'package:tickerless/core/widgets/summary_row.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_bloc.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_event.dart';

/// Choose an amount and turn a discovery into a position.
class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({required this.args, super.key});

  final PurchaseArgs args;

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  static const _amounts = [1, 5, 10, 25];

  int _amount = 5;

  @override
  Widget build(BuildContext context) {
    final company = widget.args.company;
    final tokens = _amount / company.price;

    return FlowScaffold(
      title: 'Buy ${company.symbol}',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '\$${company.price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
          ),
          const Text(
            'Demo market price',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Icon(Icons.travel_explore, size: 18, color: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.args.source,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Amount', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: _amounts
                .map(
                  (value) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(value == 25 ? 'Custom' : '\$$value'),
                        selected: _amount == value,
                        onSelected: (_) => setState(() => _amount = value),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          HairlineList(
            gap: 28,
            children: [
              SummaryRow(
                label: 'You’ll receive',
                value: '${tokens.toStringAsFixed(4)} ${company.symbol}',
              ),
              const SummaryRow(label: 'Network', value: 'Base Sepolia'),
              const SummaryRow(label: 'Asset type', value: 'Demo equity'),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              context.read<PortfolioBloc>().add(
                PurchaseRecorded(
                  company: company,
                  invested: _amount.toDouble(),
                  tokens: tokens,
                  source: widget.args.source,
                ),
              );
              context.push(
                AppRoutes.receipt,
                extra: ReceiptArgs(
                  company: company,
                  invested: _amount.toDouble(),
                  tokens: tokens,
                  source: widget.args.source,
                ),
              );
            },
            child: const Text('Review Purchase'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Demo transaction using test assets. No real funds are required.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
