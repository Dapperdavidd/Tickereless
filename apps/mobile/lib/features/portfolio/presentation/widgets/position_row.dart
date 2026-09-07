import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/features/discovery/presentation/widgets/company_avatar.dart';
import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';

/// One holding, with what led the user to it.
class PositionRow extends StatelessWidget {
  const PositionRow({required this.position, super.key});

  final OwnedPosition position;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CompanyAvatar(company: position.company, radius: 19),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              position.company.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              position.company.symbol,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 3),
            Text(
              'via ${position.sources.join(', ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.blue, fontSize: 11.5),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${position.invested.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 3),
          Text(
            '+${position.company.change}%',
            style: const TextStyle(color: AppColors.green, fontSize: 11.5),
          ),
        ],
      ),
    ],
  );
}
