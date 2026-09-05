import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/space_orb.dart';
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
    subtitle: 'Everything that caught your attention.',
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Filter('All', selected: true),
            _Filter('Lens'),
            _Filter('Link'),
            _Filter('Search'),
          ],
        ),
      ),
      _SectionLabel('Today'),
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
      _SectionLabel('Yesterday'),
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
    subtitle: 'Your identity in the ownership layer.',
    children: [
      GlassCard(
        child: Row(
          children: [
            SpaceOrb(size: 64),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explorer',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '0x3f...7a9d  ⧉',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      _SignOutButton(),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            const Text(
              '+1.2%',
              style: TextStyle(color: AppColors.green, fontSize: 11),
            ),
            const Icon(Icons.show_chart, color: AppColors.blue, size: 28),
          ],
        ),
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

class _Filter extends StatelessWidget {
  const _Filter(this.label, {this.selected = false});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
    decoration: BoxDecoration(
      color: selected ? Colors.white : AppColors.surface,
      border: Border.all(color: selected ? Colors.white : AppColors.border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: selected ? Colors.black : Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();
  @override
  Widget build(BuildContext context) =>
      OutlinedButton(onPressed: () {}, child: const Text('Sign Out'));
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
