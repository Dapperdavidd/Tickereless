import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// The three tabs, each keeping its own navigation stack.
///
/// Labels keep the three top-level destinations obvious at a glance while the
/// compact selected pill gives users a reliable sense of place.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const _destinations = [
    (icon: Icons.grid_view_rounded, label: 'Discover'),
    (icon: Icons.public_rounded, label: 'World'),
    (icon: Icons.account_balance_wallet_rounded, label: 'Wallet'),
  ];

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: light
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFDCEFFF),
                        Color(0xFFF4F9FD),
                        Color(0xFFFFFFFF),
                      ],
                    )
                  : AppColors.appGradient,
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: const Alignment(.85, -.72),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withValues(alpha: .12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          shell,
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: light ? Colors.white.withValues(alpha: .86) : null,
          border: Border(
            top: BorderSide(
              color: light ? const Color(0xFFBED0DA) : AppColors.border,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (final (index, destination) in _destinations.indexed)
                  Expanded(
                    child: _NavButton(
                      icon: destination.icon,
                      label: destination.label,
                      selected: index == shell.currentIndex,
                      foreground: foreground,
                      // A second tap on the current tab returns that branch to
                      // its root, which is what re-tapping a tab should do.
                      onTap: () => shell.goBranch(
                        index,
                        initialLocation: index == shell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.blue.withValues(alpha: .14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? foreground : AppColors.muted,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected ? foreground : AppColors.muted,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
