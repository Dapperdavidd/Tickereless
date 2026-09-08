import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tickerless/features/discovery/presentation/brand_palette.dart';

/// A company's own mark, tinted to whatever the surface needs.
///
/// The bundled marks are monochrome silhouettes rather than the full-colour
/// logos on purpose: they sit on brand-coloured tiles, where a second set of
/// brand colours would fight the field behind it. Any company we do not ship
/// a mark for falls back to a short ticker monogram, so a resolver result
/// never renders as a misleading generic company icon or an empty hole.
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
      return SizedBox.square(
        dimension: size,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            ticker.characters.take(4).toString(),
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
