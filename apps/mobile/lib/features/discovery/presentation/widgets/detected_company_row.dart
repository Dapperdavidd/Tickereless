import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Row(
      children: [
        CompanyAvatar(company: match.company, radius: 21),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.company.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                match.reason,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
              ),
              const SizedBox(height: 2),
              Text(
                '${match.company.symbol} · Base Sepolia',
                style: const TextStyle(color: AppColors.blue, fontSize: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(match.confidence * 100).round()}%',
          style: const TextStyle(
            color: AppColors.green,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: AppColors.muted,
        ),
      ],
    ),
  );
}
