import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tickerless/features/market/domain/entities/price_series.dart';

/// The price line, drawn edge to edge with a brand-coloured bloom behind it.
///
/// Painted rather than assembled from a charting package: the whole visual is
/// a glow, a fade and a stroke, and a package would bring axes, gridlines and
/// tooltips that all have to be switched back off.
class PriceChart extends StatefulWidget {
  const PriceChart({
    required this.series,
    required this.color,
    this.height = 224,
    super.key,
  });

  final PriceSeries series;
  final Color color;
  final double height;

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void didUpdateWidget(PriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching range redraws the line from the left rather than morphing
    // between two unrelated shapes.
    if (oldWidget.series.range != widget.series.range) {
      _selectedIndex = null;
      _controller.forward(from: 0);
    }
  }

  void _select(double x, double width) {
    if (widget.series.values.isEmpty || width <= 0) return;
    final last = widget.series.values.length - 1;
    final index = ((x.clamp(0, width) / width) * last).round();
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex;
    final value = selected == null ? null : widget.series.values[selected];
    return Semantics(
      label: 'Price chart for ${widget.series.range.label}',
      value: value == null
          ? 'From ${widget.series.open.toStringAsFixed(2)} to ${widget.series.close.toStringAsFixed(2)} dollars. Drag across the chart for details.'
          : '${value.toStringAsFixed(2)} dollars, point ${selected! + 1} of ${widget.series.values.length}',
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final markerX = selected == null || widget.series.values.length < 2
                ? 0.0
                : width * selected / (widget.series.values.length - 1);
            final tooltipLeft = (markerX - 40).clamp(
              8.0,
              (width - 88).clamp(8.0, double.infinity),
            );
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _select(details.localPosition.dx, width),
              onHorizontalDragStart: (details) =>
                  _select(details.localPosition.dx, width),
              onHorizontalDragUpdate: (details) =>
                  _select(details.localPosition.dx, width),
              onHorizontalDragEnd: (_) => setState(() => _selectedIndex = null),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => CustomPaint(
                        painter: _PriceChartPainter(
                          values: widget.series.values,
                          color: widget.color,
                          progress: Curves.easeOutCubic.transform(
                            _controller.value,
                          ),
                          selectedIndex: selected,
                        ),
                      ),
                    ),
                  ),
                  if (value != null)
                    Positioned(
                      top: 6,
                      left: tooltipLeft,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: Text(
                            '\$${value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  _PriceChartPainter({
    required this.values,
    required this.color,
    required this.progress,
    required this.selectedIndex,
  });

  final List<double> values;
  final Color color;
  final double progress;
  final int? selectedIndex;

  /// Vertical breathing room so the peak and trough never touch the edges.
  static const _inset = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final span = high - low;
    final usableHeight = size.height - _inset * 2;

    Offset pointAt(int index) {
      final x = size.width * (index / (values.length - 1));
      // A flat series would divide by zero, so it sits on the centre line.
      final t = span == 0 ? .5 : (values[index] - low) / span;
      return Offset(x, _inset + usableHeight * (1 - t));
    }

    // The bloom sits behind everything and is what makes the line feel lit
    // rather than drawn on a flat panel.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, .35),
          radius: .9,
          colors: [color.withValues(alpha: .17), Colors.transparent],
        ).createShader(Offset.zero & size),
    );

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var index = 1; index < values.length; index++) {
      final point = pointAt(index);
      line.lineTo(point.dx, point.dy);
    }

    // Clipping the reveal rather than extracting a sub-path keeps the fill and
    // the stroke growing together.
    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .22), Colors.transparent],
        ).createShader(Offset.zero & size),
    );

    canvas
      ..drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.1
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..restore();

    // A dot on the leading edge while the line draws, so a mid-animation
    // frame reads as drawing rather than as a line that got cut off. It is
    // dropped at rest: the final point sits on the right edge, where a dot
    // would be half outside the canvas.
    if (progress < 1) {
      final head = pointAt(((values.length - 1) * progress).round());
      canvas
        ..drawCircle(head, 7, Paint()..color = color.withValues(alpha: .22))
        ..drawCircle(head, 3, Paint()..color = color);
    }

    if (selectedIndex case final index?) {
      final selected = pointAt(index);
      canvas
        ..drawLine(
          Offset(selected.dx, _inset),
          Offset(selected.dx, size.height - _inset),
          Paint()
            ..color = color.withValues(alpha: .38)
            ..strokeWidth = 1,
        )
        ..drawCircle(selected, 8, Paint()..color = color.withValues(alpha: .2))
        ..drawCircle(selected, 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_PriceChartPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.selectedIndex != selectedIndex;
}
