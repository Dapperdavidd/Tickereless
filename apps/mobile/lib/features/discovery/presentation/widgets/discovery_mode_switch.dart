import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// Lens / Link / Search, as a segmented control over the camera.
class DiscoveryModeSwitch extends StatelessWidget {
  const DiscoveryModeSwitch({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  static const _modes = ['Lens', 'Link', 'Search'];

  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xDD061016),
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        for (final mode in _modes)
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(mode),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: mode == selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mode,
                  style: TextStyle(
                    color: mode == selected ? Colors.black : Colors.white,
                    fontSize: mode == selected ? 14 : 12,
                    fontWeight: mode == selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
