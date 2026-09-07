import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// A small static label chip — product names, result categories.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label, style: const TextStyle(fontSize: 11)),
    backgroundColor: AppColors.surfaceRaised,
    side: const BorderSide(color: AppColors.border),
  );
}
