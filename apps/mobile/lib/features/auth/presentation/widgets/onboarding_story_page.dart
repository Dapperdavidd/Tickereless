import 'package:flutter/material.dart';

/// One page of the onboarding story.
class OnboardingStoryPage extends StatelessWidget {
  const OnboardingStoryPage({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.showMethods = false,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String body;

  /// The last page lists the three ways in, instead of prose.
  final bool showMethods;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxHeight < 430;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: compact ? 18 : 42),
            Text(
              eyebrow,
              style: const TextStyle(
                color: Color(0xFFAFC3CF),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
            SizedBox(height: compact ? 8 : 13),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 34 : 42,
                height: .92,
                fontWeight: FontWeight.w700,
                letterSpacing: -2.1,
              ),
            ),
            SizedBox(height: compact ? 12 : 19),
            Container(
              width: 30,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 17),
              Text(
                body,
                style: const TextStyle(
                  color: Color(0xFFD5E0E6),
                  fontSize: 14,
                  height: 1.42,
                  letterSpacing: -.1,
                  shadows: [Shadow(color: Colors.black, blurRadius: 12)],
                ),
              ),
            ],
            if (showMethods) ...[
              SizedBox(height: compact ? 12 : 20),
              _DiscoveryMethods(compact: compact),
            ],
            const Spacer(),
          ],
        ),
      );
    },
  );
}

class _DiscoveryMethods extends StatelessWidget {
  const _DiscoveryMethods({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _DiscoveryMethod(
        icon: Icons.camera_alt_outlined,
        label: 'Scan anything',
        detail: 'Products, logos, receipts',
        compact: compact,
      ),
      SizedBox(height: compact ? 6 : 10),
      _DiscoveryMethod(
        icon: Icons.search_rounded,
        label: 'Search naturally',
        detail: 'No tickers needed',
        compact: compact,
      ),
      SizedBox(height: compact ? 6 : 10),
      _DiscoveryMethod(
        icon: Icons.link_rounded,
        label: 'Paste a link',
        detail: 'Articles, websites, anything',
        compact: compact,
      ),
    ],
  );
}

class _DiscoveryMethod extends StatelessWidget {
  const _DiscoveryMethod({
    required this.icon,
    required this.label,
    required this.detail,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final String detail;
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: compact ? 46 : 58,
    child: Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: Colors.white),
        ),
        Container(width: 1, height: 30, color: const Color(0xFF30434E)),
        const SizedBox(width: 14),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              detail,
              style: const TextStyle(color: Color(0xFF94A8B4), fontSize: 10),
            ),
          ],
        ),
      ],
    ),
  );
}
