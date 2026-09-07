import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tickerless/features/discovery/presentation/brand_palette.dart';

/// A company's own mark, tinted to whatever the surface needs.
///
/// The bundled marks are monochrome silhouettes rather than the full-colour
/// logos on purpose: they sit on brand-coloured tiles, where a second set of
/// brand colours would fight the field behind it. Any company we do not ship
/// a mark for falls back to a stand-in glyph, so a resolver result never
/// renders as a hole.
class CompanyLogo extends StatelessWidget {
  const CompanyLogo({
    required this.ticker,
    required this.size,
    required this.color,
    super.key,
  });

  final String ticker;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final asset = BrandPalette.logoAssetFor(ticker);
    if (asset == null) {
      return Icon(BrandPalette.iconFor(ticker), size: size, color: color);
    }
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
