import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A bundled token mark with a text fallback for unknown assets.
class TokenLogo extends StatelessWidget {
  const TokenLogo({required this.symbol, required this.size, super.key});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalized = symbol.toUpperCase();
    if (normalized != 'USDC' && normalized != 'ETH') {
      return CircleAvatar(
        radius: size / 2,
        child: Text(
          normalized.characters.take(1).toString(),
          style: TextStyle(fontSize: size * .38, fontWeight: FontWeight.w700),
        ),
      );
    }
    return Semantics(
      image: true,
      label: '$normalized token logo',
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: SvgPicture.asset(
            'assets/tokens/$normalized.svg',
            width: size,
            height: size,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
