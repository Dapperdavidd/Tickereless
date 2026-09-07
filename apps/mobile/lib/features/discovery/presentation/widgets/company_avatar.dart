import 'package:flutter/material.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/discovery/presentation/brand_palette.dart';

/// A company's brand mark, in the one place that decides how it looks.
class CompanyAvatar extends StatelessWidget {
  const CompanyAvatar({
    required this.company,
    this.radius = 20,
    this.borderRadius,
    super.key,
  });

  final Company company;
  final double radius;

  /// Set for a squircle tile instead of a circle.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final color = BrandPalette.colorFor(company.ticker);
    final glyph = Icon(
      BrandPalette.iconFor(company.ticker),
      color: Colors.black,
      size: radius * 1.15,
    );

    if (borderRadius == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color,
        child: glyph,
      );
    }
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      child: glyph,
    );
  }
}
