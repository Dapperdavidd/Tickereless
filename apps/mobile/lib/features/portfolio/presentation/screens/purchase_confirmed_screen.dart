import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/hairline_list.dart';
import 'package:tickerless/core/widgets/summary_row.dart';
import 'package:tickerless/core/constant/chain_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// The receipt. Both ways out lead back into the app, not back through the
/// purchase flow the user just finished.
class PurchaseConfirmedScreen extends StatelessWidget {
  const PurchaseConfirmedScreen({required this.args, super.key});

  final ReceiptArgs args;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _OwnershipBurst(),
            const SizedBox(height: 12),
            Text(
              'You now own\n${args.company.name}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\$${args.invested.toStringAsFixed(0)} · '
              '${args.tokens.toStringAsFixed(4)} ${args.company.symbol}',
              style: const TextStyle(fontSize: 18),
            ),
            const Text(
              'on Base Sepolia',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            HairlineList(
              gap: 28,
              children: [
                SummaryRow(label: 'Discovered via', value: args.source),
                SummaryRow(
                  label: 'Transaction',
                  value: args.transactionHash == null
                      ? 'Confirmed on Base'
                      : 'View on BaseScan ↗',
                  onTap: args.transactionHash == null
                      ? null
                      : () => launchUrl(
                          Uri.parse(
                            '${ChainConfig.explorerUrl}/tx/${args.transactionHash}',
                          ),
                        ),
                ),
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go(AppRoutes.activity),
              child: const Text('View in Wallet'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.discover),
              child: const Text('Make Another Discovery'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OwnershipBurst extends StatefulWidget {
  const _OwnershipBurst();

  @override
  State<_OwnershipBurst> createState() => _OwnershipBurstState();
}

class _OwnershipBurstState extends State<_OwnershipBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 128,
    width: 260,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(260, 128),
            painter: _ConfettiPainter(progress: _controller.value),
          ),
          Transform.scale(
            scale: Curves.elasticOut.transform(_controller.value),
            child: const CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              child: Icon(Icons.check, color: Colors.black, size: 42),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress});
  final double progress;

  static const _colors = [
    Color(0xFF69C8FF),
    Color(0xFF36F46B),
    Color(0xFFFFB24A),
    Color(0xFFFF6F91),
    Color(0xFF9B7BFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var index = 0; index < 28; index++) {
      final angle = index / 28 * math.pi * 2;
      final distance =
          Curves.easeOutCubic.transform(progress) * (48 + (index % 5) * 8);
      final fall = progress * progress * 24;
      final point =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance + fall);
      final opacity = (1 - ((progress - .68) / .32)).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle + progress * 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -6, 6, 12),
          const Radius.circular(2),
        ),
        Paint()
          ..color = _colors[index % _colors.length].withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
