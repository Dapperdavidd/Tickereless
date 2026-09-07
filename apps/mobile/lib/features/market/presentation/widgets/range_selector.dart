import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/features/market/domain/entities/chart_range.dart';

/// The chart's time windows.
class RangeSelector extends StatelessWidget {
  const RangeSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ChartRange selected;
  final ValueChanged<ChartRange> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final range in ChartRange.values)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => onSelected(range),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: range == selected
                    ? AppColors.surfaceRaised
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                range.label,
                style: TextStyle(
                  color: range == selected ? Colors.white : AppColors.muted,
                  fontSize: 12.5,
                  fontWeight: range == selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
