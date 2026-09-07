import 'package:flutter/material.dart';

/// One cell of a [MasonryGrid]: a child plus the shape it wants to occupy.
class MasonryItem {
  const MasonryItem({required this.aspectRatio, required this.child});

  /// Width ÷ height. Below 1 is a tall tile, above 1 a wide one.
  final double aspectRatio;
  final Widget child;
}

/// A two-column staggered grid.
///
/// Written out rather than pulled from a package because the layout is the
/// whole point of the screen: each item goes into whichever column is
/// currently shorter, which is what stops the two columns from drifting into
/// a ragged edge as tile heights vary.
class MasonryGrid extends StatelessWidget {
  const MasonryGrid({required this.items, this.gutter = 8, super.key});

  final List<MasonryItem> items;
  final double gutter;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columnWidth = (constraints.maxWidth - gutter) / 2;
      final columns = <List<Widget>>[[], []];
      final heights = <double>[0, 0];

      for (final item in items) {
        final height = columnWidth / item.aspectRatio;
        final target = heights[0] <= heights[1] ? 0 : 1;

        if (columns[target].isNotEmpty) {
          columns[target].add(SizedBox(height: gutter));
        }
        columns[target].add(
          SizedBox(width: columnWidth, height: height, child: item.child),
        );
        heights[target] += height + gutter;
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: columnWidth,
            child: Column(children: columns[0]),
          ),
          SizedBox(width: gutter),
          SizedBox(
            width: columnWidth,
            child: Column(children: columns[1]),
          ),
        ],
      );
    },
  );
}
