import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// A muted label on the left, an emphasised value on the right.
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    required this.label,
    required this.value,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted)),
      const SizedBox(width: 18),
      Flexible(
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: onTap == null ? null : AppColors.blue,
            ),
          ),
        ),
      ),
    ],
  );
}
