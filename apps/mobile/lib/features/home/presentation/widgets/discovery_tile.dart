import 'package:flutter/material.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/discovery/presentation/brand_palette.dart';
import 'package:tickerless/features/discovery/presentation/widgets/company_logo.dart';

/// A company as a full-bleed tile.
///
/// There is no company photography yet, so the artwork is built from the
/// brand itself: a saturated field, a soft highlight, and the mark scaled up
/// until it runs off the edge. That reads as a composed image rather than as
/// an icon sitting in a card, which is the difference between this and a list
/// row with a border.
class DiscoveryTile extends StatelessWidget {
  const DiscoveryTile({required this.company, required this.onTap, super.key});

  final Company company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BrandPalette.colorFor(company.ticker);
    final ink = BrandPalette.inkOn(company.ticker);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(brand, Colors.white, .18)!,
                    brand,
                    Color.lerp(brand, Colors.black, .42)!,
                  ],
                  stops: const [0, .45, 1],
                ),
              ),
            ),
            // The mark is cropped deliberately: a shape running off the tile
            // edge reads as artwork, a centred one reads as an app icon.
            Positioned(
              right: -30,
              bottom: -26,
              child: CompanyLogo(
                ticker: company.ticker,
                size: 138,
                color: ink.withValues(alpha: .17),
              ),
            ),
            const _BottomScrim(),
            Positioned(
              left: 14,
              right: 14,
              bottom: 13,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          company.symbol,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink.withValues(alpha: .62),
                            fontSize: 11,
                            letterSpacing: .2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+${company.change}%',
                        style: TextStyle(
                          color: ink.withValues(alpha: .82),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps the label legible over whatever the artwork does underneath it.
class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.black.withValues(alpha: .38), Colors.transparent],
        stops: const [0, .48],
      ),
    ),
  );
}
