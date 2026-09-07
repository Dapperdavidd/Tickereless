import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/features/discovery/domain/entities/company_match.dart';
import 'package:tickerless/features/discovery/presentation/widgets/company_avatar.dart';

/// A search result: who it is, why the resolver thinks so, and a way in.
class CompanyResultCard extends StatelessWidget {
  const CompanyResultCard({
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${match.company.symbol} · Base Sepolia',
                    style: const TextStyle(color: AppColors.blue, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.muted,
            ),
          ],
        ),
        const SizedBox(height: 11),
        Text(
          match.reason,
          style: const TextStyle(height: 1.45, color: Color(0xFFD4DEE3)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'View Company →',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .92),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
