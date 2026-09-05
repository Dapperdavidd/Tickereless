import 'package:flutter/material.dart';

import '../models/company.dart';
import '../services/api_client.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

void openScreen(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController(text: 'company behind instagram');
  final api = TickerlessApi();
  List<CompanyMatch>? matches;
  String? error;
  bool loading = false;

  Future<void> submit() async {
    if (controller.text.trim().isEmpty) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await api.search(controller.text.trim());
      if (mounted) setState(() => matches = result);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Could not reach the resolver. Check that the Rust API is running.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FlowScaffold(
    title: 'Search',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => submit(),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: submit,
              icon: const Icon(Icons.arrow_upward),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          children: [
            _Pill('All'),
            _Pill('Companies'),
            _Pill('Products'),
            _Pill('Ideas'),
          ],
        ),
        const SizedBox(height: 24),
        const GlassCard(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFE94592),
                child: Icon(Icons.camera_alt_outlined, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instagram',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'A product of Meta Platforms',
                      style: TextStyle(color: AppColors.blue, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (loading) const Center(child: CircularProgressIndicator()),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(error!, style: const TextStyle(color: AppColors.red)),
          ),
        ...(matches ??
                [
                  const CompanyMatch(
                    company: DemoCompanies.meta,
                    reason: 'Instagram is a product of Meta Platforms',
                    confidence: .98,
                  ),
                ])
            .map(
              (match) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompanyResult(
                  company: match.company,
                  reason: match.reason,
                  onTap: () => openScreen(
                    context,
                    PassportScreen(
                      company: match.company,
                      source: '“${controller.text.trim()}” · Search',
                    ),
                  ),
                ),
              ),
            ),
        const SizedBox(height: 22),
        const Text(
          'Related results',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const _RelatedRow(
          icon: Icons.facebook,
          title: 'Facebook',
          subtitle: 'A product of Meta',
        ),
        const _RelatedRow(
          icon: Icons.message,
          title: 'WhatsApp',
          subtitle: 'A product of Meta',
        ),
        const _RelatedRow(
          icon: Icons.alternate_email,
          title: 'Threads',
          subtitle: 'A product of Meta',
        ),
      ],
    ),
  );
}

class LensScreen extends StatelessWidget {
  const LensScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/lens-phone.png',
              fit: BoxFit.cover,
            ),
          ),
          const Positioned(left: 20, top: 14, child: BackButton()),
          const Positioned(right: 24, top: 24, child: Icon(Icons.flash_on)),
          Center(
            child: Container(
              width: 280,
              height: 310,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 26,
            child: Column(
              children: [
                const Text(
                  'Apple',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                const Text(
                  'iPhone detected',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () => openScreen(
                    context,
                    const PassportScreen(
                      company: DemoCompanies.apple,
                      source: 'iPhone · Lens',
                    ),
                  ),
                  child: const Text('Explore Apple'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class LinkScreen extends StatelessWidget {
  const LinkScreen({super.key});

  @override
  Widget build(BuildContext context) => _FlowScaffold(
    title: 'Analyze a link',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const TextField(
          controller: null,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.link),
            hintText: 'https://theverge.com/nvidia-ai',
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Row(
            children: [
              const Icon(
                Icons.article_outlined,
                size: 38,
                color: AppColors.blue,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'NVIDIA’s next AI chips could change everything',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Companies detected',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _DetectedCompany(
          company: DemoCompanies.nvidia,
          confidence: '92%',
          role: 'Primary subject',
        ),
        const _DetectedCompany(
          company: DemoCompanies.meta,
          confidence: '24%',
          role: 'Mentioned',
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: () => openScreen(
            context,
            const PassportScreen(
              company: DemoCompanies.nvidia,
              source: 'AI hardware article · Link',
            ),
          ),
          child: const Text('View NVIDIA'),
        ),
      ],
    ),
  );
}

class PassportScreen extends StatelessWidget {
  const PassportScreen({
    required this.company,
    required this.source,
    super.key,
  });
  final Company company;
  final String source;

  @override
  Widget build(BuildContext context) => Scaffold(
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
                company.color.withValues(alpha: .18),
                AppColors.background,
              ],
            ),
          ),
          child: Center(
            child: CircleAvatar(
              radius: 52,
              backgroundColor: company.color,
              child: Icon(
                company == DemoCompanies.apple ? Icons.apple : Icons.memory,
                color: Colors.black,
                size: 58,
              ),
            ),
          ),
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
        Wrap(spacing: 8, children: company.products.map(_Pill.new).toList()),
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
                child: Icon(Icons.show_chart, color: AppColors.green, size: 52),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () =>
              openScreen(context, BuyScreen(company: company, source: source)),
          child: Text('Own ${company.name}'),
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
              Expanded(child: Text(source)),
            ],
          ),
        ),
      ],
    ),
  );
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

class BuyScreen extends StatefulWidget {
  const BuyScreen({required this.company, required this.source, super.key});
  final Company company;
  final String source;

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  int amount = 5;

  @override
  Widget build(BuildContext context) {
    final tokens = amount / widget.company.price;
    return _FlowScaffold(
      title: 'Buy ${widget.company.symbol}',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '\$${widget.company.price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
          ),
          const Text(
            'Demo market price',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.travel_explore),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.source)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('Amount', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [1, 5, 10, 25]
                .map(
                  (value) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(value == 25 ? 'Custom' : '\$$value'),
                        selected: amount == value,
                        onSelected: (_) => setState(() => amount = value),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              children: [
                _SummaryRow(
                  label: 'You’ll receive',
                  value:
                      '${tokens.toStringAsFixed(4)} ${widget.company.symbol}',
                ),
                const SizedBox(height: 14),
                const _SummaryRow(label: 'Network', value: 'Base Sepolia'),
                const SizedBox(height: 14),
                const _SummaryRow(label: 'Asset type', value: 'Demo equity'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              appStore.record(
                widget.company,
                amount.toDouble(),
                tokens,
                widget.source,
              );
              openScreen(
                context,
                ConfirmedScreen(
                  company: widget.company,
                  amount: amount,
                  tokens: tokens,
                  source: widget.source,
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

class ConfirmedScreen extends StatelessWidget {
  const ConfirmedScreen({
    required this.company,
    required this.amount,
    required this.tokens,
    required this.source,
    super.key,
  });
  final Company company;
  final int amount;
  final double tokens;
  final String source;

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
              'You now own\n${company.name}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\$$amount · ${tokens.toStringAsFixed(4)} ${company.symbol}',
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
                  _SummaryRow(label: 'Discovered via', value: source),
                  const SizedBox(height: 14),
                  const _SummaryRow(
                    label: 'Transaction',
                    value: 'View on BaseScan ↗',
                  ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('View in Your World'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Make Another Discovery'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FlowScaffold extends StatelessWidget {
  const _FlowScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: child,
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label, style: const TextStyle(fontSize: 11)),
    backgroundColor: AppColors.surfaceRaised,
    side: const BorderSide(color: AppColors.border),
  );
}

class _CompanyResult extends StatelessWidget {
  const _CompanyResult({
    required this.company,
    required this.reason,
    required this.onTap,
  });
  final Company company;
  final String reason;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: company.color,
              child: const Icon(Icons.public, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${company.symbol} · Base Sepolia',
                    style: const TextStyle(color: AppColors.blue, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(reason, style: const TextStyle(height: 1.4)),
        const SizedBox(height: 14),
        OutlinedButton(onPressed: onTap, child: const Text('View Company →')),
      ],
    ),
  );
}

class _RelatedRow extends StatelessWidget {
  const _RelatedRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.blue),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
  );
}

class _DetectedCompany extends StatelessWidget {
  const _DetectedCompany({
    required this.company,
    required this.confidence,
    required this.role,
  });
  final Company company;
  final String confidence;
  final String role;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4),
    leading: CircleAvatar(
      backgroundColor: company.color,
      child: const Icon(Icons.memory, color: Colors.black),
    ),
    title: Text(
      company.name,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      '$role\n${company.symbol} · Base',
      style: const TextStyle(fontSize: 11),
    ),
    trailing: Text(
      confidence,
      style: const TextStyle(
        color: AppColors.green,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted)),
      const SizedBox(width: 18),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
