import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// A label-over-value stat.
typedef Stat = ({String label, String value});

/// Facts in a row, separated by hairlines rather than boxed into cards.
class StatStrip extends StatelessWidget {
  const StatStrip({required this.stats, super.key});

  final List<Stat> stats;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, stat) in stats.indexed) ...[
          if (index > 0)
            const VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 4,
              endIndent: 4,
              color: AppColors.border,
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
