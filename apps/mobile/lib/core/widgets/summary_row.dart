import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// A muted label on the left, an emphasised value on the right.
class SummaryRow extends StatelessWidget {
  const SummaryRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted)),
      const SizedBox(width: 18),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
