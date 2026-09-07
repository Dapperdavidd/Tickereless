import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// The three tabs, each keeping its own navigation stack.
///
/// Icon-only and unlabelled: three destinations this distinct do not need
/// captions, and dropping them keeps the bar out of the content's way.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const _destinations = [
    (icon: Icons.grid_view_rounded, label: 'Discover'),
    (icon: Icons.public_rounded, label: 'World'),
    (icon: Icons.account_balance_wallet_rounded, label: 'Wallet'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (final (index, destination) in _destinations.indexed)
                Expanded(
                  child: _NavButton(
                    icon: destination.icon,
                    label: destination.label,
                    selected: index == shell.currentIndex,
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Icon(
            icon,
            size: 23,
            color: selected ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    ),
  );
}
