import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/features/activity/domain/entities/discovery_event.dart';
import 'package:tickerless/features/activity/presentation/widgets/activity_filters.dart';
import 'package:tickerless/features/activity/presentation/widgets/history_row.dart';
import 'package:tickerless/features/discovery/domain/entities/discovery_source.dart';
import 'package:tickerless/features/portfolio/presentation/widgets/tab_list.dart';

/// Everything that caught the user's attention, newest first.
///
/// The history is still the demo's fixed set — there is no event store behind
/// it yet, so this reads from a constant rather than a repository.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  static const _history = [
    DiscoveryEvent(
      title: 'iPhone',
      company: 'Apple',
      symbol: 'tAAPLc',
      source: DiscoverySource.lens,
      owned: true,
      day: 'Today',
    ),
    DiscoveryEvent(
      title: 'NVIDIA article',
      company: 'NVIDIA',
      symbol: 'tNVDAc',
      source: DiscoverySource.link,
      owned: false,
      day: 'Today',
    ),
    DiscoveryEvent(
      title: '“company behind Instagram”',
      company: 'Meta',
      symbol: 'tMETAc',
      source: DiscoverySource.search,
      owned: true,
      day: 'Today',
    ),
    DiscoveryEvent(
      title: '“AI chips”',
      company: 'NVIDIA',
      symbol: 'tNVDAc',
      source: DiscoverySource.search,
      owned: false,
      day: 'Yesterday',
    ),
  ];

  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final visible = _filter == 'All'
        ? _history
        : _history
              .where((event) => event.source.label == _filter)
              .toList(growable: false);

    return TabList(
      title: 'Discovery History',
      subtitle: 'Everything that caught your attention.',
      children: [
        ActivityFilters(
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        for (final day in {for (final event in visible) event.day}) ...[
          _SectionLabel(day),
          ...visible
              .where((event) => event.day == day)
              .map((event) => HistoryRow(event: event)),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
