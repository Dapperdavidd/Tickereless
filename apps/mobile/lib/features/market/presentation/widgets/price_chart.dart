import 'package:flutter/material.dart';
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
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    width: double.infinity,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _PriceChartPainter(
          values: widget.series.values,
          color: widget.color,
          progress: Curves.easeOutCubic.transform(_controller.value),
        ),
      ),
    ),
  );
}

class _PriceChartPainter extends CustomPainter {
  _PriceChartPainter({
    required this.values,
    required this.color,
    required this.progress,
  });

  final List<double> values;
  final Color color;
  final double progress;

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
  }

  @override
  bool shouldRepaint(_PriceChartPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.values != values ||
      oldDelegate.color != color;
}
