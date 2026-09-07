import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/glass_card.dart';
import 'package:tickerless/features/discovery/domain/entities/company_match.dart';
import 'package:tickerless/features/discovery/presentation/widgets/company_avatar.dart';

/// A company found on a page, with the resolver's confidence in it.
class DetectedCompanyRow extends StatelessWidget {
  const DetectedCompanyRow({
    required this.match,
    required this.onTap,
    super.key,
  });

  final CompanyMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    child: Row(
      children: [
        CompanyAvatar(
          company: match.company,
          radius: 23,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.company.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                match.reason,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              Text(
                '${match.company.symbol} · Base Sepolia',
                style: const TextStyle(color: AppColors.blue, fontSize: 11),
              ),
            ],
          ),
        ),
        Text(
          '${(match.confidence * 100).round()}%',
          style: const TextStyle(
            color: AppColors.green,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}
