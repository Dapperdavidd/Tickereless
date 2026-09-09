import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/error/failures.dart';
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
  static const _amounts = [1.0, 5.0, 10.0];

  double _amount = 5;
  bool _buying = false;

  Future<void> _buy() async {
    final session = context.read<AuthBloc>().state.session;
    if (session == null) return;
    setState(() => _buying = true);
    try {
      final result = await context.read<ChainGateway>().buy(
        userId: session.userId,
        company: widget.args.company,
        usdc: _amount,
      );
      if (!mounted) return;
      context.read<PortfolioBloc>().add(
        PurchaseRecorded(
          company: widget.args.company,
          invested: _amount,
          tokens: result.tokens,
          source: widget.args.source,
        ),
      );
      context.push(
        AppRoutes.receipt,
        extra: ReceiptArgs(
          company: widget.args.company,
          invested: _amount,
          tokens: result.tokens,
          source: widget.args.source,
          transactionHash: result.hash,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final failure = error is WalletFailure
          ? error
          : const WalletFailure(
              'We couldn’t complete this purchase. Try again in a moment.',
            );
      final needsWallet =
          failure.kind == WalletFailureKind.needsNetworkFee ||
          failure.kind == WalletFailureKind.insufficientBalance;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            content: Text(failure.message),
            action: needsWallet
                ? SnackBarAction(
                    label: 'Open wallet',
                    onPressed: () => context.go(AppRoutes.activity),
                  )
                : null,
          ),
        );
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  Future<void> _typeAmount() async {
    final controller = TextEditingController(
      text: _amount.toStringAsFixed(_amount == _amount.roundToDouble() ? 0 : 2),
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter an amount'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: r'$ ',
            suffixText: 'USDC',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              Navigator.pop(context, value);
            },
            child: const Text('Use amount'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount != null && amount > 0 && mounted) {
      setState(() => _amount = amount.clamp(1, 100));
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
          InkWell(
            onTap: _typeAmount,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    '\$${_amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.4,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: AppColors.blue,
                  ),
                ],
              ),
            ),
          ),
          Text(
            'USDC to invest · ${company.symbol} price \$${company.price.toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.muted),
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
                        label: Text('\$${value.toStringAsFixed(0)}'),
                        selected: _amount == value,
                        onSelected: (_) => setState(() => _amount = value),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.blue,
              inactiveTrackColor: Theme.of(context).dividerColor,
              thumbColor: Theme.of(context).colorScheme.onSurface,
              tickMarkShape: const RoundSliderTickMarkShape(
                tickMarkRadius: 1.2,
              ),
              activeTickMarkColor: Colors.white54,
              inactiveTickMarkColor: AppColors.muted,
            ),
            child: Slider(
              value: _amount.clamp(1, 100),
              min: 1,
              max: 100,
              divisions: 99,
              label: '\$${_amount.toStringAsFixed(0)}',
              onChanged: (value) => setState(() => _amount = value),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$1',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              Text(
                'Slide or tap the amount to type',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              Text(
                '\$100',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
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
