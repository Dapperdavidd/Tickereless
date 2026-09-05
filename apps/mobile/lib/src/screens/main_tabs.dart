import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../state/app_store.dart';

class WorldScreen extends StatelessWidget {
  const WorldScreen({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: appStore,
    builder: (context, _) => _TabList(
      title: 'Your World',
      subtitle:
          '${appStore.positions.length} companies · ${appStore.discoveryCount} discoveries · \$${appStore.total.toStringAsFixed(2)}',
      children: [
        ...appStore.positions.map(
          (position) => _Position(
            name: position.company.name,
            symbol: position.company.symbol,
            amount: '\$${position.invested.toStringAsFixed(2)}',
            source: position.sources.join(', '),
            color: position.company.color,
          ),
        ),
        const GlassCard(
          child: Text(
            'Everyday things.\nExtraordinary ownership.',
            style: TextStyle(
              fontSize: 23,
              height: 1.05,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});
  @override
  Widget build(BuildContext context) => const _TabList(
    title: 'Discovery History',
    subtitle: 'The path from attention to ownership.',
    children: [
      _History(
        icon: Icons.center_focus_strong,
        title: 'iPhone',
        detail: 'Apple · tAAPLc',
        status: 'Owned',
      ),
      _History(
        icon: Icons.link,
        title: 'NVIDIA article',
        detail: 'NVIDIA · tNVDAc',
        status: 'Viewed',
      ),
      _History(
        icon: Icons.search,
        title: '“company behind Instagram”',
        detail: 'Meta · tMETAc',
        status: 'Owned',
      ),
      _History(
        icon: Icons.search,
        title: '“AI chips”',
        detail: 'NVIDIA · tNVDAc',
        status: 'Viewed',
      ),
    ],
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const _TabList(
    title: 'You',
    subtitle: 'Explorer · 0x3f...7a9d',
    children: [
      _Setting(icon: Icons.settings_outlined, label: 'Settings'),
      _Setting(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Connected Wallet',
      ),
      _Setting(icon: Icons.notifications_none, label: 'Notifications'),
      _Setting(icon: Icons.dark_mode_outlined, label: 'Appearance · Dark'),
      _Setting(icon: Icons.help_outline, label: 'Help & Support'),
      _Setting(icon: Icons.info_outline, label: 'About Tickerless'),
      GlassCard(
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.blue),
            SizedBox(width: 12),
            Text(
              'Base Sepolia · Demo assets',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TabList extends StatelessWidget {
  const _TabList({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 24),
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 24),
        ...children.expand((child) => [child, const SizedBox(height: 12)]),
      ],
    ),
  );
}

class _Position extends StatelessWidget {
  const _Position({
    required this.name,
    required this.symbol,
    required this.amount,
    required this.source,
    required this.color,
  });
  final String name;
  final String symbol;
  final String amount;
  final String source;
  final Color color;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: color,
          child: const Icon(Icons.public, color: Colors.black),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                symbol,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              Text(
                'Discovered via $source',
                style: const TextStyle(color: AppColors.blue, fontSize: 11),
              ),
            ],
          ),
        ),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _History extends StatelessWidget {
  const _History({
    required this.icon,
    required this.title,
    required this.detail,
    required this.status,
  });
  final IconData icon;
  final String title;
  final String detail;
  final String status;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.surfaceRaised,
          child: Icon(icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                detail,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: status == 'Owned' ? AppColors.green : AppColors.muted,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

class _Setting extends StatelessWidget {
  const _Setting({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
