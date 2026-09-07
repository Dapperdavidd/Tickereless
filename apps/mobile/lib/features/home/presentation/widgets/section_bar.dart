import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// The section title, with the portfolio hanging off the right as a link
/// rather than sitting in a card of its own.
class SectionBar extends StatelessWidget {
  const SectionBar({
    required this.title,
    required this.trailing,
    required this.onTrailingTap,
    super.key,
  });

  final String title;
  final String trailing;
  final VoidCallback onTrailingTap;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -.5,
        ),
      ),
      const Spacer(),
      // The portfolio total is the variable-width part, so it is the part
      // that gives way when the row runs out of room.
      Flexible(
        child: GestureDetector(
          onTap: onTrailingTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  trailing,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
