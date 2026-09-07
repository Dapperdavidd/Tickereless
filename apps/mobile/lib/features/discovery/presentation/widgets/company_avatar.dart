import 'package:flutter/material.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/discovery/presentation/brand_palette.dart';
import 'package:tickerless/features/discovery/presentation/widgets/company_logo.dart';

/// A company's brand mark on its brand colour, in the one place that decides
/// how it looks.
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
    final mark = Center(
      child: CompanyLogo(
        ticker: company.ticker,
        // Marks are wider than a Material glyph at the same nominal size, so
        // they sit smaller inside the circle to keep the optical margin even.
        size: radius,
        color: BrandPalette.inkOn(company.ticker),
      ),
    );

    if (borderRadius == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: BrandPalette.colorFor(company.ticker),
        child: mark,
      );
    }
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: BrandPalette.colorFor(company.ticker),
        borderRadius: borderRadius,
      ),
      child: mark,
    );
  }
}
