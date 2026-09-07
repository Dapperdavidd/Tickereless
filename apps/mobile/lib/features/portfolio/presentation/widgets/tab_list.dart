import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// The big-title list layout the World, Activity, and Profile screens share.
class TabList extends StatelessWidget {
  const TabList({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
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
