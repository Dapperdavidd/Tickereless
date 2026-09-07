import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/glass_card.dart';
import 'package:tickerless/features/discovery/presentation/brand_palette.dart';
import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';

/// The Discover tab's glance at what the user already owns.
class PortfolioPreviewCard extends StatelessWidget {
  const PortfolioPreviewCard({
    required this.positions,
    required this.total,
    required this.onTap,
    super.key,
  });

  final List<OwnedPosition> positions;
  final double total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your World', style: TextStyle(fontWeight: FontWeight.w700)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(
              Icons.show_chart_rounded,
              color: AppColors.blue,
              size: 46,
            ),
          ],
        ),
        const Text(
          '+2.45% today',
          style: TextStyle(color: AppColors.green, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Three fit across the card; the rest live on the World tab.
            for (final position in positions.take(3)) ...[
              Expanded(child: _MiniPosition(position: position)),
              if (position != positions.take(3).last)
                const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    ),
  );
}

class _MiniPosition extends StatelessWidget {
  const _MiniPosition({required this.position});

  final OwnedPosition position;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: BrandPalette.colorFor(position.company.ticker),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${position.company.ticker}c',
          style: const TextStyle(fontSize: 11),
        ),
        Text(
          '\$${position.invested.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
