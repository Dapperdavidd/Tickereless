import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// A row of filters. The selected one is a filled pill; the rest are just
/// words — an outline on every option makes four buttons compete for the same
/// attention the content needs.
class FilterChips extends StatelessWidget {
  const FilterChips({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelected(option),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: option == selected
                      ? AppColors.surfaceRaised
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: option == selected ? Colors.white : AppColors.muted,
                    fontSize: 12.5,
                    fontWeight: option == selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
