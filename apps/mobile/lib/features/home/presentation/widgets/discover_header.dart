import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/tickerless_wordmark.dart';
import 'package:tickerless/features/profile/presentation/widgets/current_profile_avatar.dart';

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
      Flexible(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/tickerless-icon.png',
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 9),
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: TickerlessWordmark(compact: true),
              ),
            ),
          ],
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
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const CurrentProfileAvatar(size: 28),
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
