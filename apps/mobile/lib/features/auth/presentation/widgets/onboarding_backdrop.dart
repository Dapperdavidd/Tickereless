import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The parallax world behind the onboarding story: a star field and a single
/// wide earth image, both scrolled by the page controller so the three pages
/// read as one continuous journey.
class OnboardingBackdrop extends StatelessWidget {
  const OnboardingBackdrop({
    required this.controller,
    required this.viewportWidth,
    required this.pageCount,
    super.key,
  });

  final PageController controller;
  final double viewportWidth;
  final int pageCount;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      _ParallaxLayer(
        controller: controller,
        viewportWidth: viewportWidth,
        pageCount: pageCount,
        // Stars drift slightly slower than the ground, which is what sells
        // the depth.
        factor: .84,
        child: const RepaintBoundary(
          child: CustomPaint(painter: _StarFieldPainter()),
        ),
      ),
      _ParallaxLayer(
        controller: controller,
        viewportWidth: viewportWidth,
        pageCount: pageCount,
        factor: 1,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: const Offset(0, -4),
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                ],
                stops: [0, .2, .42, 1],
              ).createShader(bounds),
              child: Image.asset(
                'assets/images/earth-journey-v4.png',
                width: viewportWidth * pageCount,
                fit: BoxFit.fitWidth,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
      const _EdgeVignette(),
    ],
  );
}

class _ParallaxLayer extends StatelessWidget {
  const _ParallaxLayer({
    required this.controller,
    required this.viewportWidth,
    required this.pageCount,
    required this.factor,
    required this.child,
  });

  final PageController controller;
  final double viewportWidth;
  final int pageCount;
  final double factor;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) {
      final position = controller.hasClients
          ? (controller.page ?? controller.initialPage.toDouble())
          : controller.initialPage.toDouble();
      return Transform.translate(
        offset: Offset(-position * viewportWidth * factor, 0),
        child: child,
      );
    },
    child: OverflowBox(
      alignment: Alignment.centerLeft,
      maxWidth: viewportWidth * pageCount,
      minWidth: viewportWidth * pageCount,
      child: SizedBox(width: viewportWidth * pageCount, child: child),
    ),
  );
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(1709);
    for (var index = 0; index < 186; index++) {
      final x = random.nextDouble() * size.width;
      final y = 60 + random.nextDouble() * size.height * .68;
      final radius = .35 + random.nextDouble() * 1.05;
      final opacity = .18 + random.nextDouble() * .52;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EdgeVignette extends StatelessWidget {
  const _EdgeVignette();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.black.withValues(alpha: .12),
            Colors.transparent,
            Colors.black.withValues(alpha: .22),
            Colors.black,
          ],
          stops: const [0, .19, .43, .72, 1],
        ),
      ),
    ),
  );
}
