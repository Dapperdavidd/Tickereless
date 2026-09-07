import 'package:flutter/material.dart';
import 'package:tickerless/core/widgets/glass_card.dart';

class SettingTile extends StatelessWidget {
  const SettingTile({
    required this.icon,
    required this.label,
    this.detail,
    this.onTap,
    super.key,
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
