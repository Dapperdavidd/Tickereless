import 'package:flutter/material.dart';
import 'package:tickerless/core/widgets/glass_card.dart';

/// One of the three ways in: Lens, Link, Search.
class EntryTile extends StatelessWidget {
  const EntryTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
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
