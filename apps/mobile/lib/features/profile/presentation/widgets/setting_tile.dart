import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// A settings row: icon, label, optional detail, chevron. No box.
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14.5)),
              if (detail != null) ...[
                const SizedBox(height: 3),
                Text(
                  detail!,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: AppColors.muted,
        ),
      ],
    ),
  );
}
