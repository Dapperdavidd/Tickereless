import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// Rows on the background, separated by a hairline.
///
/// This replaced a bordered card per row: a list of eight cards draws eight
/// rounded rectangles to communicate one thing — that these are separate
/// items — which a single line between them says more quietly.
class HairlineList extends StatelessWidget {
  const HairlineList({required this.children, this.gap = 26, super.key});

  final List<Widget> children;

  /// Total height of the separator, line included.
  final double gap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, child) in children.indexed) ...[
        if (index > 0)
          Divider(height: gap, thickness: 1, color: AppColors.border),
        child,
      ],
    ],
  );
}
