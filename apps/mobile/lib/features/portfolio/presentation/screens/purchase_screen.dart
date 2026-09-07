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
import 'package:tickerless/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tickerless/features/wallet/data/base_sepolia_gateway.dart';

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
  bool _buying = false;
  String? _error;

  Future<void> _buy() async {
    final session = context.read<AuthBloc>().state.session;
    if (session == null) return;
    setState(() {
      _buying = true;
      _error = null;
    });
    try {
      final result = await context.read<ChainGateway>().buy(
        userId: session.userId,
        company: widget.args.company,
        usdc: _amount.toDouble(),
      );
      if (!mounted) return;
      context.read<PortfolioBloc>().add(
        PurchaseRecorded(
          company: widget.args.company,
          invested: _amount.toDouble(),
          tokens: result.tokens,
          source: widget.args.source,
        ),
      );
      context.push(
        AppRoutes.receipt,
        extra: ReceiptArgs(
          company: widget.args.company,
          invested: _amount.toDouble(),
          tokens: result.tokens,
          source: widget.args.source,
          transactionHash: result.hash,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

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
            'Base Sepolia market price',
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
              const SummaryRow(label: 'Settlement', value: 'USDC'),
            ],
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppColors.red)),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: _buying ? null : _buy,
            child: Text(_buying ? 'Confirming on Base…' : 'Buy with USDC'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Uses testnet USDC and Base Sepolia ETH. Testnet assets have no monetary value.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
