import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/glass_card.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/discovery/presentation/widgets/company_avatar.dart';

/// A company other people are discovering right now.
class TrendingRow extends StatelessWidget {
  const TrendingRow({required this.company, required this.onTap, super.key});

  final Company company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    child: Row(
      children: [
        CompanyAvatar(company: company),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '${company.symbol} · ${company.products.first}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${company.change}%',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text('Own', style: TextStyle(fontSize: 10)),
          ],
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 18),
      ],
    ),
  );
}
