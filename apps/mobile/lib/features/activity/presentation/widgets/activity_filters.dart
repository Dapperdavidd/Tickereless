import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// Scrollable filter row across discovery methods.
class ActivityFilters extends StatelessWidget {
  const ActivityFilters({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  static const options = ['All', 'Lens', 'Link', 'Search'];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(option),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: option == selected ? Colors.white : AppColors.surface,
                  border: Border.all(
                    color: option == selected
                        ? Colors.white
                        : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: option == selected ? Colors.black : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
