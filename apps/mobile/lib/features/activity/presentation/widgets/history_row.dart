import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/glass_card.dart';
import 'package:tickerless/features/activity/domain/entities/discovery_event.dart';
import 'package:tickerless/features/discovery/domain/entities/discovery_source.dart';

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
  Widget build(BuildContext context) => GlassCard(
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.surfaceRaised,
          child: Icon(iconFor(event.source)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '${event.company} · ${event.symbol}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          event.owned ? 'Owned' : 'Viewed',
          style: TextStyle(
            color: event.owned ? AppColors.green : AppColors.muted,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}
