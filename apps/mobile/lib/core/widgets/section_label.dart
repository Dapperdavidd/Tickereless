import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// A quiet heading over a group of rows.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppColors.muted,
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      letterSpacing: .3,
    ),
  );
}
