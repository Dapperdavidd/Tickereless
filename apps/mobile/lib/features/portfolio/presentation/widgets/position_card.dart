import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/glass_card.dart';
import 'package:tickerless/features/discovery/presentation/brand_palette.dart';
import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';

/// One holding, with what led the user to it.
class PositionCard extends StatelessWidget {
  const PositionCard({required this.position, super.key});

  final OwnedPosition position;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: BrandPalette.colorFor(position.company.ticker),
          child: const Icon(Icons.public, color: Colors.black),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                position.company.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                position.company.symbol,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              Text(
                'Discovered via ${position.sources.join(', ')}',
                style: const TextStyle(color: AppColors.blue, fontSize: 11),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${position.invested.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              '+${position.company.change}%',
              style: const TextStyle(color: AppColors.green, fontSize: 11),
            ),
            const Icon(Icons.show_chart, color: AppColors.blue, size: 28),
          ],
        ),
      ],
    ),
  );
}
