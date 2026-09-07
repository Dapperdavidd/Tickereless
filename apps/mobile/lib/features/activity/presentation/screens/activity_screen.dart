import 'package:flutter/material.dart';
import 'package:tickerless/core/widgets/filter_chips.dart';
import 'package:tickerless/core/widgets/hairline_list.dart';
import 'package:tickerless/core/widgets/section_label.dart';
import 'package:tickerless/features/activity/domain/entities/discovery_event.dart';
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
  static const _filters = ['All', 'Lens', 'Link', 'Search'];

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
        FilterChips(
          options: _filters,
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 8),
        for (final day in {for (final event in visible) event.day}) ...[
          SectionLabel(day),
          const SizedBox(height: 14),
          HairlineList(
            children: [
              for (final event in visible.where((event) => event.day == day))
                HistoryRow(event: event),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (visible.isEmpty)
          const Text(
            'Nothing discovered this way yet.',
            style: TextStyle(color: Color(0xFF8DA1AD)),
          ),
      ],
    );
  }
}
