import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
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
import 'package:tickerless/features/profile/presentation/widgets/current_profile_avatar.dart';
import 'package:tickerless/features/wallet/domain/entities/wallet_identity.dart';
import 'package:tickerless/features/wallet/data/base_sepolia_gateway.dart';
import 'package:tickerless/features/wallet/presentation/widgets/token_logo.dart';
import 'package:wallet/wallet.dart';

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
          return _LiveWallet(
            key: ValueKey(address),
            address: address,
            portfolio: portfolio,
          );
        },
      );
    },
  );
}

/// Keeps the on-chain snapshot live while the wallet tab remains mounted.
/// Polling catches incoming transfers; lifecycle refresh catches funds received
/// while the app was backgrounded; explicit refreshes cover in-app sends.
class _LiveWallet extends StatefulWidget {
  const _LiveWallet({
    required this.address,
    required this.portfolio,
    super.key,
  });

  final String address;
  final PortfolioState portfolio;

  @override
  State<_LiveWallet> createState() => _LiveWalletState();
}

class _LiveWalletState extends State<_LiveWallet> with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 12);
  Timer? _timer;
  OnChainSnapshot? _snapshot;
  DateTime? _lastSynced;
  bool _refreshing = false;
  bool _chainError = false;
  bool _balancesHidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
    _timer = Timer.periodic(_pollInterval, (_) => unawaited(_refresh()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<OnChainSnapshot> _fetch() =>
      context.read<ChainGateway>().snapshot(widget.address);

  Future<void> _refresh() async {
    if (!mounted || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      final next = await _fetch();
      if (!mounted) return;
      setState(() {
        _snapshot = next;
        _lastSynced = DateTime.now();
        _chainError = false;
        _refreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chainError = true;
        _refreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _WalletBody(
    address: widget.address,
    portfolio: widget.portfolio,
    chain: _snapshot,
    chainError: _chainError,
    isRefreshing: _refreshing,
    lastSynced: _lastSynced,
    balancesHidden: _balancesHidden,
    onToggleBalances: () => setState(() => _balancesHidden = !_balancesHidden),
    onRefresh: _refresh,
  );
}

class _WalletBody extends StatelessWidget {
  const _WalletBody({
    required this.address,
    required this.portfolio,
    this.chain,
    this.chainError = false,
    this.isRefreshing = false,
    this.balancesHidden = false,
    this.lastSynced,
    this.onToggleBalances,
    this.onRefresh,
  });
  final String? address;
  final PortfolioState portfolio;
  final OnChainSnapshot? chain;
  final bool chainError;
  final bool isRefreshing;
  final bool balancesHidden;
  final DateTime? lastSynced;
  final VoidCallback? onToggleBalances;
  final Future<void> Function()? onRefresh;

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
        onRefresh: () async {
          context.read<PortfolioBloc>().add(const PortfolioRequested());
          await onRefresh?.call();
        },
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
                Tooltip(
                  message: 'Open profile',
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.profile),
                    child: const CurrentProfileAvatar(size: 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      button: onToggleBalances != null,
                      label: balancesHidden
                          ? 'Hidden wallet balance. Double tap to show.'
                          : 'Wallet balance ${total.toStringAsFixed(2)} dollars. Double tap to hide.',
                      child: InkWell(
                        onTap: onToggleBalances,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ExcludeSemantics(
                            child: Text(
                              balancesHidden
                                  ? '••••••'
                                  : '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 46,
                                height: 1,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onToggleBalances,
                  tooltip: balancesHidden ? 'Show balances' : 'Hide balances',
                  icon: Icon(
                    balancesHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    balancesHidden
                        ? 'Performance hidden'
                        : '${dailyChange >= 0 ? '+' : ''}${dailyChange.toStringAsFixed(2)}% today',
                    style: TextStyle(
                      color: balancesHidden
                          ? AppColors.muted
                          : dailyChange >= 0
                          ? AppColors.green
                          : AppColors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: isRefreshing ? null : onRefresh,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRefreshing)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        else
                          Icon(
                            chainError
                                ? Icons.cloud_off_outlined
                                : Icons.cloud_done_outlined,
                            size: 14,
                            color: chainError ? AppColors.red : AppColors.green,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          _syncLabel(),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                for (final (index, action) in [
                  (
                    Icons.arrow_upward_rounded,
                    'Send',
                    chain == null ? null : () => _showSend(context, chain!),
                  ),
                  (
                    Icons.arrow_downward_rounded,
                    'Receive',
                    address == null
                        ? null
                        : () => _showReceive(context, address!),
                  ),
                ].indexed)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : 5,
                        right: index == 1 ? 0 : 5,
                      ),
                      child: _WalletAction(
                        icon: action.$1,
                        label: action.$2,
                        onTap: action.$3,
                      ),
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
                  _UsdcRow(balance: chain!.usdc, balanceHidden: balancesHidden),
                  _EthRow(balance: chain!.eth, balanceHidden: balancesHidden),
                  for (final position in positions)
                    _AssetRow(
                      position: position,
                      balanceHidden: balancesHidden,
                    ),
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

  void _showReceive(BuildContext context, String walletAddress) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Receive on Base Sepolia',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Only send Base Sepolia ETH or USDC to this address.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: QrImageView(data: walletAddress, size: 160),
                ),
              ),
              const SizedBox(height: 18),
              SelectableText(
                walletAddress,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: walletAddress));
                  if (!context.mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Wallet address copied.')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy address'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSend(BuildContext context, OnChainSnapshot balance) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: _SendSheet(balance: balance, gateway: context.read()),
      ),
    );
    if (sent == true) await onRefresh?.call();
  }

  String _syncLabel() {
    if (isRefreshing && chain == null) return 'Connecting…';
    if (isRefreshing) return 'Updating…';
    if (chainError) {
      return chain == null ? 'Unavailable · Retry' : 'Offline · Retry';
    }
    final synced = lastSynced;
    if (synced == null) return 'Base Sepolia';
    final elapsed = DateTime.now().difference(synced);
    if (elapsed.inMinutes < 1) return 'Live · now';
    return 'Live · ${elapsed.inMinutes}m ago';
  }
}

class _UsdcRow extends StatelessWidget {
  const _UsdcRow({required this.balance, required this.balanceHidden});
  final double balance;
  final bool balanceHidden;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () => context.push(
      AppRoutes.currencyAsset,
      extra: CurrencyAssetArgs(symbol: 'USDC', balance: balance),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const TokenLogo(symbol: 'USDC', size: 42),
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
            balanceHidden ? '••••' : '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.muted,
          ),
        ],
      ),
    ),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
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
  const _EthRow({required this.balance, required this.balanceHidden});
  final double balance;
  final bool balanceHidden;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () => context.push(
      AppRoutes.currencyAsset,
      extra: CurrencyAssetArgs(symbol: 'ETH', balance: balance),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const TokenLogo(symbol: 'ETH', size: 42),
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
            balanceHidden ? '••••' : balance.toStringAsFixed(6),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.muted,
          ),
        ],
      ),
    ),
  );
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      height: 76,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
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

class _SendSheet extends StatefulWidget {
  const _SendSheet({required this.balance, required this.gateway});
  final OnChainSnapshot balance;
  final ChainGateway gateway;

  @override
  State<_SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<_SendSheet> {
  final _recipient = TextEditingController();
  final _amount = TextEditingController();
  String _asset = 'USDC';
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _recipient.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _reviewAndSend() async {
    final session = context.read<AuthBloc>().state.session;
    final amount = double.tryParse(_amount.text.trim());
    final recipient = _recipient.text.trim();
    if (session == null || amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid recipient and amount.');
      return;
    }
    try {
      EthereumAddress.fromHex(recipient);
    } catch (_) {
      setState(() => _error = 'Enter a valid 0x wallet address.');
      return;
    }
    final available = _asset == 'USDC'
        ? widget.balance.usdc
        : widget.balance.eth;
    if (amount > available) {
      setState(() => _error = 'Your available $_asset balance is too low.');
      return;
    }
    if (_asset == 'ETH' && amount >= available) {
      setState(() => _error = 'Leave some ETH behind for the network fee.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => _TransferReviewSheet(
        asset: _asset,
        amount: amount,
        recipient: recipient,
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await HapticFeedback.mediumImpact();
      if (_asset == 'USDC') {
        await widget.gateway.sendUsdc(
          userId: session.userId,
          recipient: recipient,
          amount: amount,
        );
      } else {
        await widget.gateway.sendEth(
          userId: session.userId,
          recipient: recipient,
          amount: amount,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(
        SnackBar(content: Text('$amount $_asset sent on Base Sepolia.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = error.toString().replaceFirst('Failure: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final available = _asset == 'USDC'
        ? '\$${widget.balance.usdc.toStringAsFixed(2)}'
        : '${widget.balance.eth.toStringAsFixed(6)} ETH';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'USDC', label: Text('USDC')),
                ButtonSegment(value: 'ETH', label: Text('Base Sepolia ETH')),
              ],
              selected: {_asset},
              onSelectionChanged: (value) =>
                  setState(() => _asset = value.single),
            ),
            const SizedBox(height: 10),
            Text(
              'Available: $available',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _recipient,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Recipient address'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: 'Amount in $_asset'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.red)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _sending ? null : _reviewAndSend,
              child: Text(_sending ? 'Confirming on Base…' : 'Review and send'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Testnet assets have no monetary value. Network fees use Base Sepolia ETH.',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferReviewSheet extends StatelessWidget {
  const _TransferReviewSheet({
    required this.asset,
    required this.amount,
    required this.recipient,
  });

  final String asset;
  final double amount;
  final String recipient;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: AppColors.blue),
              SizedBox(width: 10),
              Text(
                'Review transaction',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Confirm every detail before this transaction is submitted.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 22),
          _ReviewRow(
            label: 'You send',
            value: '${_formatAmount(amount)} $asset',
          ),
          const Divider(height: 26, color: AppColors.border),
          _ReviewRow(label: 'Network', value: 'Base Sepolia'),
          const Divider(height: 26, color: AppColors.border),
          const _ReviewRow(
            label: 'Network fee',
            value: 'Calculated on submission',
          ),
          const SizedBox(height: 18),
          const Text(
            'Recipient',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 7),
          SelectableText(
            recipient,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'TESTNET · These assets have no monetary value. Transactions cannot be undone after submission.',
              style: TextStyle(fontSize: 11.5, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm and send'),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Go back and edit'),
            ),
          ),
        ],
      ),
    ),
  );

  static String _formatAmount(double value) {
    if (value.truncateToDouble() == value) return value.toStringAsFixed(0);
    return value
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      const SizedBox(width: 16),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    ],
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
  const _AssetRow({required this.position, required this.balanceHidden});
  final OwnedPosition position;
  final bool balanceHidden;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () => context.push(
      AppRoutes.passport,
      extra: PassportArgs(
        company: position.company,
        source: 'Owned asset · Wallet',
        position: position,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
                balanceHidden
                    ? '••••'
                    : '\$${position.invested.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                balanceHidden
                    ? 'Hidden'
                    : '${position.tokens.toStringAsFixed(4)} tokens',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.muted,
          ),
        ],
      ),
    ),
  );
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});
  final PortfolioTransaction transaction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 18,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.south_west_rounded, size: 17),
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
