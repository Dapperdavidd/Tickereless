import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/constant/chain_config.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_state.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/discovery/presentation/brand_palette.dart';
import 'package:tickerless/features/discovery/presentation/widgets/company_avatar.dart';
import 'package:tickerless/features/market/domain/entities/news_article.dart';
import 'package:tickerless/features/market/domain/usecases/get_company_news.dart';
import 'package:tickerless/features/market/domain/usecases/get_price_series.dart';
import 'package:tickerless/features/market/presentation/bloc/passport_bloc.dart';
import 'package:tickerless/features/market/presentation/bloc/passport_event.dart';
import 'package:tickerless/features/market/presentation/bloc/passport_state.dart';
import 'package:tickerless/features/market/presentation/widgets/news_list.dart';
import 'package:tickerless/features/market/presentation/widgets/price_chart.dart';
import 'package:tickerless/features/market/presentation/widgets/range_selector.dart';
import 'package:tickerless/features/market/presentation/widgets/stat_strip.dart';
import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';
import 'package:tickerless/features/wallet/data/base_sepolia_gateway.dart';

/// Everything known about one company, and the way to own a piece of it.
///
/// The page is a price, a chart and three facts — so it is laid out as those
/// things, separated by hairlines. Wrapping each one in its own bordered card
/// added six rectangles and no information.
class PassportScreen extends StatelessWidget {
  const PassportScreen({required this.args, super.key});

  final PassportArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => PassportBloc(
      getPriceSeries: context.read<GetPriceSeriesUseCase>(),
      getCompanyNews: context.read<GetCompanyNewsUseCase>(),
      ticker: args.company.ticker,
      anchorPrice: args.company.price,
    )..add(const PassportOpened()),
    child: _PassportView(args: args),
  );
}

class _PassportView extends StatelessWidget {
  const _PassportView({required this.args});

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
    final brand = BrandPalette.colorFor(company.ticker);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Row(
          children: [
            CompanyAvatar(company: company, radius: 14),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                company.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.ios_share_outlined, size: 21),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded, size: 21),
          ),
        ],
      ),
      body: BlocBuilder<PassportBloc, PassportState>(
        builder: (context, state) => ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _PriceHeadline(company: company, state: state),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 224,
              child: state.series == null
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : PriceChart(series: state.series!, color: brand),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RangeSelector(
                selected: state.range,
                onSelected: (range) => context.read<PassportBloc>().add(
                  PassportRangeSelected(range),
                ),
              ),
            ),
            if (state.series?.isDemo ?? false) ...[
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Demo series · not market data',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
            ],
            const Divider(height: 30, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StatStrip(
                stats: [
                  (label: 'Token', value: company.symbol),
                  (label: 'Network', value: 'Base Sepolia'),
                  (label: 'Asset type', value: 'Test token'),
                ],
              ),
            ),
            const Divider(height: 30, color: AppColors.border),
            if (args.position case final position?) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StatStrip(
                  stats: [
                    (
                      label: 'You own',
                      value: '${position.tokens.toStringAsFixed(4)} tokens',
                    ),
                    (
                      label: 'Position',
                      value: '\$${position.invested.toStringAsFixed(2)}',
                    ),
                    (
                      label: 'Today',
                      value:
                          '${company.change >= 0 ? '+' : ''}${company.change.toStringAsFixed(2)}%',
                    ),
                  ],
                ),
              ),
              const Divider(height: 30, color: AppColors.border),
            ],
            _PassportTabs(company: company, articles: state.articles),
            const Divider(height: 30, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Row(
                children: [
                  const Icon(
                    Icons.travel_explore,
                    color: AppColors.blue,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      args.source,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _OwnBar(
        company: company,
        position: args.position,
        onOwn: () => _own(context),
      ),
    );
  }
}

/// The price, and the move that goes with it.
class _PriceHeadline extends StatelessWidget {
  const _PriceHeadline({required this.company, required this.state});

  final Company company;
  final PassportState state;

  @override
  Widget build(BuildContext context) {
    // Before the first series lands, the company's own daily move stands in,
    // so the number never flashes from one value to another.
    final change = state.series?.change ?? company.change;
    final isUp = change >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\$${company.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 40,
            height: 1.05,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isUp ? Icons.north_east_rounded : Icons.south_east_rounded,
              size: 15,
              color: isUp ? AppColors.green : AppColors.red,
            ),
            const SizedBox(width: 4),
            Text(
              '${change.abs().toStringAsFixed(2)}%',
              style: TextStyle(
                color: isUp ? AppColors.green : AppColors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              state.range.label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ],
        ),
      ],
    );
  }
}

/// About / Products / News — previously three words that did nothing.
class _PassportTabs extends StatefulWidget {
  const _PassportTabs({required this.company, required this.articles});

  final Company company;
  final List<NewsArticle> articles;

  @override
  State<_PassportTabs> createState() => _PassportTabsState();
}

class _PassportTabsState extends State<_PassportTabs> {
  static const _tabs = ['About', 'Products', 'News'];

  int _index = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            for (final (index, tab) in _tabs.indexed)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _index = index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Text(
                        tab,
                        style: TextStyle(
                          color: index == _index
                              ? Colors.white
                              : AppColors.muted,
                          fontSize: 13,
                          fontWeight: index == _index
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 9),
                      // The rule under the active tab is the only selected
                      // state, so it carries the full weight.
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 2,
                        color: index == _index
                            ? Colors.white
                            : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: switch (_index) {
          0 => Text(
            widget.company.description,
            style: const TextStyle(height: 1.55, color: Color(0xFFD4DEE3)),
          ),
          1 => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final product in widget.company.products)
                Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(product, style: const TextStyle(fontSize: 14.5)),
                    ],
                  ),
                ),
            ],
          ),
          _ => NewsList(articles: widget.articles),
        },
      ),
    ],
  );
}

/// The one action on the page, pinned so it never scrolls away.
class _OwnBar extends StatefulWidget {
  const _OwnBar({
    required this.company,
    required this.position,
    required this.onOwn,
  });

  final Company company;
  final OwnedPosition? position;
  final VoidCallback onOwn;

  @override
  State<_OwnBar> createState() => _OwnBarState();
}

class _OwnBarState extends State<_OwnBar> {
  bool _selling = false;

  Future<void> _sell() async {
    final position = widget.position;
    final session = context.read<AuthBloc>().state.session;
    if (position == null || session == null || _selling) return;
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SellAmountSheet(
        symbol: widget.company.symbol,
        maximumUsdc: position.invested,
      ),
    );
    if (amount == null || !mounted) return;
    final tokens = position.tokens * (amount / position.invested);
    setState(() => _selling = true);
    try {
      final result = await context.read<ChainGateway>().sell(
        userId: session.userId,
        company: widget.company,
        tokens: tokens,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '\$${result.usdc.toStringAsFixed(2)} USDC returned to your wallet.',
          ),
        ),
      );
      context.go(AppRoutes.activity);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Failure: ', ''))),
      );
      setState(() => _selling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supported = ChainConfig.assets.containsKey(widget.company.ticker);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (widget.position != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _selling ? null : _sell,
                        child: Text(_selling ? 'Selling…' : 'Sell'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: widget.position == null ? 1 : 2,
                    child: BlocBuilder<AuthBloc, AuthState>(
                      buildWhen: (previous, current) =>
                          previous.mode != current.mode,
                      builder: (context, _) => FilledButton(
                        onPressed: supported ? widget.onOwn : null,
                        child: Text(
                          supported
                              ? widget.position == null
                                    ? 'Own ${widget.company.name}'
                                    : 'Buy more ${widget.company.name}'
                              : 'News only on testnet',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Transactions use testnet USDC and have no monetary value.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellAmountSheet extends StatefulWidget {
  const _SellAmountSheet({required this.symbol, required this.maximumUsdc});
  final String symbol;
  final double maximumUsdc;

  @override
  State<_SellAmountSheet> createState() => _SellAmountSheetState();
}

class _SellAmountSheetState extends State<_SellAmountSheet> {
  late double _amount = widget.maximumUsdc;

  Future<void> _typeAmount() async {
    final controller = TextEditingController(text: _amount.toStringAsFixed(2));
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Amount to sell'),
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
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text.trim())),
            child: const Text('Use amount'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value > 0 && mounted) {
      setState(() => _amount = value.clamp(.01, widget.maximumUsdc));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        4,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sell ${widget.symbol}',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: _typeAmount,
            child: Row(
              children: [
                Text(
                  '\$${_amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit_rounded, size: 18, color: AppColors.blue),
              ],
            ),
          ),
          Slider(
            value: _amount,
            min: .01,
            max: widget.maximumUsdc,
            divisions: widget.maximumUsdc > 1 ? 100 : 20,
            label: '\$${_amount.toStringAsFixed(2)}',
            onChanged: (value) => setState(() => _amount = value),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Partial', style: TextStyle(color: AppColors.muted)),
              TextButton(
                onPressed: () => setState(() => _amount = widget.maximumUsdc),
                child: const Text('Max'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.pop(context, _amount),
            child: Text('Review sale · \$${_amount.toStringAsFixed(2)}'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Two Base Sepolia confirmations are required. Testnet assets have no monetary value.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}
