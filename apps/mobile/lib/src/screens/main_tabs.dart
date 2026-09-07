import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/space_orb.dart';
import '../state/app_store.dart';
import '../state/auth_state.dart';
import '../services/wallet_service.dart';
import 'email_auth_screen.dart';
import 'onboarding_screen.dart';

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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: authState,
    builder: (context, _) {
      if (authState.isGuest) {
        return _TabList(
          title: 'You',
          subtitle: 'You are exploring without a profile.',
          children: [
            const GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.person_outline_rounded, size: 34),
                  SizedBox(height: 18),
                  Text(
                    'Guest mode',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Search, scan, and discover freely. Sign in when you are ready to own test assets and create your profile.',
                    style: TextStyle(color: AppColors.muted, height: 1.45),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EmailAuthScreen(),
                ),
              ),
              child: const Text('Sign in or create account'),
            ),
          ],
        );
      }
      final address = authState.walletAddress;
      return _TabList(
        title: 'You',
        subtitle: 'Your identity in the ownership layer.',
        children: [
          GlassCard(
            child: Row(
              children: [
                const SpaceOrb(size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.session?.email ?? 'Explorer',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        address == null ? 'Preparing wallet…' : _short(address),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _Setting(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Your Wallet',
            detail: address == null ? null : _short(address),
          ),
          _Setting(
            icon: Icons.key_outlined,
            label: 'View private key',
            onTap: () => _confirmPrivateKeyReveal(context),
          ),
          const _Setting(
            icon: Icons.notifications_none,
            label: 'Notifications',
          ),
          const _Setting(
            icon: Icons.dark_mode_outlined,
            label: 'Appearance · Dark',
          ),
          const _Setting(icon: Icons.help_outline, label: 'Help & Support'),
          const _Setting(icon: Icons.info_outline, label: 'About Tickerless'),
          const GlassCard(
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
          const _SignOutButton(),
        ],
      );
    },
  );

  static String _short(String address) =>
      '${address.substring(0, 6)}…${address.substring(address.length - 4)}';

  Future<void> _confirmPrivateKeyReveal(BuildContext context) async {
    final userId = authState.session?.userId;
    if (userId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Never share your private key'),
        content: const Text(
          'Anyone with this key can control your wallet and its assets. '
          'Tickerless support will never ask for it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I understand'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final privateKey = await walletService.revealPrivateKey(userId);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Private key'),
        content: SelectableText(privateKey),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: privateKey));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Private key copied')),
                );
              }
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () {
      authState.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()),
        (_) => false,
      );
    },
    child: const Text('Sign Out'),
  );
}

class _Setting extends StatelessWidget {
  const _Setting({
    required this.icon,
    required this.label,
    this.detail,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    onTap: onTap,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: detail == null ? null : Text(detail!),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
