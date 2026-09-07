import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/tickerless_wordmark.dart';

/// The whole of the Discover chrome: a wordmark and three affordances, on one
/// line. Everything else on the screen is content.
class DiscoverHeader extends StatelessWidget {
  const DiscoverHeader({
    required this.onSearch,
    required this.onLink,
    required this.onProfile,
    super.key,
  });

  final VoidCallback onSearch;
  final VoidCallback onLink;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      // Flexible so a wide font or a narrow device shortens the wordmark
      // instead of overflowing the row.
      const Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: TickerlessWordmark(compact: true),
        ),
      ),
      const Spacer(),
      _HeaderAction(
        icon: Icons.search_rounded,
        tooltip: 'Search',
        onTap: onSearch,
      ),
      _HeaderAction(
        icon: Icons.link_rounded,
        tooltip: 'Analyze a link',
        onTap: onLink,
      ),
      const SizedBox(width: 4),
      Tooltip(
        message: 'Open profile',
        child: GestureDetector(
          onTap: onProfile,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceRaised,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 17,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ],
  );
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    iconSize: 21,
    color: Colors.white,
    icon: Icon(icon),
  );
}
