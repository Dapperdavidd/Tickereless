import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/glass_card.dart';
import 'package:tickerless/features/discovery/domain/entities/company_match.dart';
import 'package:tickerless/features/discovery/presentation/widgets/company_avatar.dart';

/// A search result: who it is, why the resolver thinks so, and a way in.
class CompanyResultCard extends StatelessWidget {
  const CompanyResultCard({required this.match, required this.onTap, super.key});

  final CompanyMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CompanyAvatar(company: match.company),
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
                    '${match.company.symbol} · Base Sepolia',
                    style: const TextStyle(color: AppColors.blue, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(match.reason, style: const TextStyle(height: 1.4)),
        const SizedBox(height: 14),
        OutlinedButton(onPressed: onTap, child: const Text('View Company →')),
      ],
    ),
  );
}
