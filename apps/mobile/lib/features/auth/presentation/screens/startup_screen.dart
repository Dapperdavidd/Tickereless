import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// A short brand transition while secure storage restores the session.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1650),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.appGradient),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final value = _controller.value;
            final movement = Curves.easeInOutCubic.transform(
              ((value - .08) / .60).clamp(0.0, 1.0),
            );
            final markOpacity = Curves.easeInCubic.transform(
              1 - ((value - .28) / .38).clamp(0.0, 1.0),
            );
            final reveal = Curves.easeOutCubic.transform(
              ((value - .38) / .34).clamp(0.0, 1.0),
            );
            return SizedBox(
              width: 310,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: markOpacity,
                    child: Transform.translate(
                      offset: Offset(-96 * movement, 0),
                      child: CustomPaint(
                        size: const Size.square(88),
                        painter: _MarkPainter(progress: movement),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 105,
                    child: ClipRect(
                      child: Align(
                        widthFactor: reveal,
                        alignment: Alignment.centerLeft,
                        child: Opacity(
                          opacity: reveal,
                          child: const Text(
                            'T I C K E R L E S S',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
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
    ),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .39;
    // Keep the end of the broken ring fixed and pull its leading edge
    // counterclockwise into it.
    final sweep = math.pi * 1.72 * (1 - progress);
    const endAngle = math.pi * .28;
    final startAngle = endAngle + sweep;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Colors.white, Color(0xFF48C7FF), Color(0xFF256BFF)],
      ).createShader(Offset.zero & size);
    if (sweep > .01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        -sweep,
        false,
        ring,
      );
    }
    final mark = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(center.dx - 22, center.dy - 10)
      ..quadraticBezierTo(
        center.dx,
        center.dy + 2,
        center.dx + 22,
        center.dy - 10,
      )
      ..quadraticBezierTo(
        center.dx + 8,
        center.dy + 4,
        center.dx + 4,
        center.dy + 7,
      )
      ..lineTo(center.dx + 4, center.dy + 31)
      ..lineTo(center.dx - 4, center.dy + 31)
      ..lineTo(center.dx - 4, center.dy + 7)
      ..quadraticBezierTo(
        center.dx - 8,
        center.dy + 4,
        center.dx - 22,
        center.dy - 10,
      )
      ..close();
    canvas.drawPath(path, mark);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
