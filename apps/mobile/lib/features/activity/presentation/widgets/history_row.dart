import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/features/activity/domain/entities/discovery_event.dart';
import 'package:tickerless/features/discovery/domain/entities/discovery_source.dart';

/// One thing the user looked at.
class HistoryRow extends StatelessWidget {
  const HistoryRow({required this.event, super.key});

  final DiscoveryEvent event;

  static IconData iconFor(DiscoverySource source) => switch (source) {
    DiscoverySource.lens => Icons.center_focus_strong,
    DiscoverySource.link => Icons.link,
    DiscoverySource.search => Icons.search,
    DiscoverySource.trending => Icons.explore,
  };

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(iconFor(event.source), size: 19, color: AppColors.muted),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${event.company} · ${event.symbol}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Text(
        event.owned ? 'Owned' : 'Viewed',
        style: TextStyle(
          color: event.owned ? AppColors.green : AppColors.muted,
          fontSize: 11.5,
          fontWeight: event.owned ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    ],
  );
}
