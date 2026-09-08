import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/hairline_list.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_state.dart';
import 'package:tickerless/features/auth/presentation/widgets/sign_in_sheet.dart';
import 'package:tickerless/features/discovery/presentation/widgets/company_avatar.dart';
import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';
import 'package:tickerless/features/portfolio/domain/entities/portfolio_transaction.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_bloc.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_event.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_state.dart';
import 'package:tickerless/features/wallet/domain/entities/wallet_identity.dart';
import 'package:tickerless/features/wallet/data/base_sepolia_gateway.dart';

/// Wallet identity, owned assets, and the transactions that produced them.
/// The historical route stays `/activity` so existing deep links keep working.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, auth) {
      if (auth.isGuest) return const _GuestWallet();
      return BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, portfolio) {
          final address = auth.walletAddress;
          if (address == null) {
            return _WalletBody(address: null, portfolio: portfolio);
          }
          return FutureBuilder<OnChainSnapshot>(
            future: context.read<ChainGateway>().snapshot(address),
            builder: (context, snapshot) => _WalletBody(
              address: address,
              portfolio: portfolio,
              chain: snapshot.data,
              chainError: snapshot.hasError,
            ),
          );
        },
      );
    },
  );
}

class _WalletBody extends StatelessWidget {
  const _WalletBody({
    required this.address,
    required this.portfolio,
    this.chain,
    this.chainError = false,
  });
  final String? address;
  final PortfolioState portfolio;
  final OnChainSnapshot? chain;
  final bool chainError;

  @override
  Widget build(BuildContext context) {
    final loaded = portfolio is PortfolioLoaded
        ? portfolio as PortfolioLoaded
        : null;
    final positions = chain?.positions ?? const <OwnedPosition>[];
    final total =
        (chain?.usdc ?? 0) +
        positions.fold<double>(0, (sum, position) => sum + position.invested);
    final dailyChange = loaded == null || total == 0
        ? 0.0
        : positions.fold<double>(
                0,
                (sum, item) => sum + item.invested * item.company.change,
              ) /
              total;
    final shortAddress = address == null
        ? 'Creating wallet…'
        : WalletIdentity(address: address!).shortAddress;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async =>
            context.read<PortfolioBloc>().add(const PortfolioRequested()),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Wallet',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
                _AddressPill(label: shortAddress, address: address),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Open profile',
                  onPressed: () => context.push(AppRoutes.profile),
                  icon: const Icon(Icons.person_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 46,
                height: 1,
                fontWeight: FontWeight.w500,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${dailyChange >= 0 ? '+' : ''}${dailyChange.toStringAsFixed(2)}% today',
              style: TextStyle(
                color: dailyChange >= 0 ? AppColors.green : AppColors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                for (final action in const [
                  (Icons.add_rounded, 'Deposit'),
                  (Icons.arrow_upward_rounded, 'Send'),
                  (Icons.arrow_downward_rounded, 'Receive'),
                  (Icons.swap_horiz_rounded, 'Swap'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _WalletAction(icon: action.$1, label: action.$2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            _SectionHeading(
              title: 'Your Assets',
              trailing: chain == null
                  ? 'Loading on-chain…'
                  : '${positions.length + 2} assets',
            ),
            const SizedBox(height: 15),
            if (chain != null)
              HairlineList(
                gap: 22,
                children: [
                  _UsdcRow(balance: chain!.usdc),
                  _EthRow(balance: chain!.eth),
                  for (final position in positions)
                    _AssetRow(position: position),
                ],
              )
            else if (chainError)
              const Text(
                'Base Sepolia balances are temporarily unavailable.',
                style: TextStyle(color: AppColors.muted),
              )
            else
              const LinearProgressIndicator(),
            const SizedBox(height: 34),
            _SectionHeading(
              title: 'Recent Transactions',
              trailing: '${loaded?.transactions.length ?? 0} total',
            ),
            const SizedBox(height: 15),
            if (loaded?.transactions.isEmpty ?? true)
              const Text(
                'Your purchases will appear here.',
                style: TextStyle(color: AppColors.muted),
              )
            else
              HairlineList(
                gap: 22,
                children: [
                  for (final transaction in loaded!.transactions)
                    _TransactionRow(transaction: transaction),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _UsdcRow extends StatelessWidget {
  const _UsdcRow({required this.balance});
  final double balance;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const CircleAvatar(
        radius: 21,
        backgroundColor: Color(0xFF2775CA),
        child: Text(r'$ ', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      const SizedBox(width: 13),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('USD Coin', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(
              'USDC · Base Sepolia',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      Text(
        '\$${balance.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _AddressPill extends StatelessWidget {
  const _AddressPill({required this.label, required this.address});
  final String label;
  final String? address;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: address == null
        ? null
        : () async {
            await Clipboard.setData(ClipboardData(text: address!));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wallet address copied.')),
              );
            }
          },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          if (address != null) ...[
            const SizedBox(width: 5),
            const Icon(Icons.copy_rounded, size: 11),
          ],
        ],
      ),
    ),
  );
}

class _EthRow extends StatelessWidget {
  const _EthRow({required this.balance});
  final double balance;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const CircleAvatar(
        radius: 21,
        backgroundColor: Color(0xFF235BFF),
        child: Icon(Icons.diamond_outlined, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 13),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Base Sepolia ETH',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              'Gas balance',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      Text(
        balance.toStringAsFixed(6),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming in the on-chain wallet step.')),
    ),
    child: Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 21),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11.5)),
        ],
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.trailing});
  final String title;
  final String trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      Text(
        trailing,
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
    ],
  );
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.position});
  final OwnedPosition position;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CompanyAvatar(company: position.company, radius: 21),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              position.company.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              position.company.symbol,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${position.invested.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            '${position.tokens.toStringAsFixed(4)} tokens',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    ],
  );
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});
  final PortfolioTransaction transaction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.surfaceRaised,
        child: Icon(Icons.south_west_rounded, size: 17),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bought ${transaction.company.symbol}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              '${transaction.source} · ${_time(transaction.occurredAt)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
      Text(
        '-\$${transaction.amount.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ],
  );

  static String _time(DateTime time) {
    final elapsed = DateTime.now().difference(time);
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    return '${elapsed.inDays}d ago';
  }
}

class _GuestWallet extends StatelessWidget {
  const _GuestWallet();
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wallet',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          const Icon(Icons.account_balance_wallet_outlined, size: 42),
          const SizedBox(height: 18),
          const Text(
            'Sign in to activate your wallet.',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your assets and transaction history will live here.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 26),
          FilledButton(
            onPressed: () => showSignInSheet(context),
            child: const Text('Sign in or create account'),
          ),
          const Spacer(),
        ],
      ),
    ),
  );
}
