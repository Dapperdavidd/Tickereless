import 'dart:math' as math;

import 'package:flutter/material.dart';

class SpaceOrb extends StatelessWidget {
  const SpaceOrb({super.key, this.size = 260});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        center: Alignment(-0.35, -0.45),
        radius: 0.85,
        colors: [
          Color(0xFFDAF1FF),
          Color(0xFF456170),
          Color(0xFF111A20),
          Color(0xFF020406),
        ],
        stops: [0, 0.2, 0.58, 1],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF93D9FF).withValues(alpha: 0.2),
          blurRadius: 32,
        ),
      ],
    ),
    child: CustomPaint(painter: _OrbitPainter()),
  );
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(11);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.36);
    for (var index = 0; index < 90; index++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final dx = x - size.width / 2;
      final dy = y - size.height / 2;
      if (dx * dx + dy * dy < size.width * size.width / 4) {
        canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.1 + 0.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
