import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The three tabs, each keeping its own navigation stack.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      // `initialLocation: true` on a re-tap returns that branch to its root,
      // which is what a second tap on the current tab should do.
      onDestinationSelected: (index) =>
          shell.goBranch(index, initialLocation: index == shell.currentIndex),
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
      ],
    ),
  );
}
