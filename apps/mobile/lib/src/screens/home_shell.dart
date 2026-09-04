import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/tickerless_wordmark.dart';
import 'experience_screens.dart';
import 'main_tabs.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    _DiscoverHome(),
    WorldScreen(),
    ActivityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _index, children: _pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Discover',
        ),
        NavigationDestination(
          icon: Icon(Icons.public_outlined),
          selectedIcon: Icon(Icons.public),
          label: 'World',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: 'Activity',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'You',
        ),
      ],
    ),
  );
}

class _DiscoverHome extends StatelessWidget {
  const _DiscoverHome();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TickerlessWordmark(compact: true),
            CircleAvatar(
              backgroundColor: AppColors.surfaceRaised,
              child: Icon(Icons.person_outline),
            ),
          ],
        ),
        const SizedBox(height: 40),
        const Text(
          'What caught\nyour attention\ntoday?',
          style: TextStyle(
            fontSize: 40,
            height: 0.94,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.6,
          ),
        ),
        const SizedBox(height: 26),
        TextField(
          readOnly: true,
          onTap: () => openScreen(context, const SearchScreen()),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search anything...',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _EntryTile(
                icon: Icons.center_focus_strong,
                label: 'Lens',
                onTap: () => openScreen(context, const LensScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EntryTile(
                icon: Icons.link,
                label: 'Link',
                onTap: () => openScreen(context, const LinkScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EntryTile(
                icon: Icons.search,
                label: 'Search',
                onTap: () => openScreen(context, const SearchScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your World',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    r'$27.00',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  Icon(
                    Icons.show_chart_rounded,
                    color: AppColors.blue,
                    size: 46,
                  ),
                ],
              ),
              const Text(
                '+2.45% today',
                style: TextStyle(color: AppColors.green, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(
                    child: _MiniPosition(
                      symbol: 'AAPLc',
                      amount: r'$14',
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _MiniPosition(
                      symbol: 'NVDAc',
                      amount: r'$8',
                      color: Color(0xFF9BFF00),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _MiniPosition(
                      symbol: 'METAc',
                      amount: r'$5',
                      color: Color(0xFF38A5FF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.blue, size: 16),
            SizedBox(width: 8),
            Text(
              'Base Sepolia · Demo assets',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 9),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

class _MiniPosition extends StatelessWidget {
  const _MiniPosition({
    required this.symbol,
    required this.amount,
    required this.color,
  });
  final String symbol;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 8),
        Text(symbol, style: const TextStyle(fontSize: 11)),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
