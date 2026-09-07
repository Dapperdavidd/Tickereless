import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/google_auth_service.dart';
import '../widgets/tickerless_wordmark.dart';
import 'home_shell.dart';

const _pageCount = 3;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  final googleAuth = GoogleAuthService();
  Timer? _autoplay;
  int page = 0;
  bool googleBusy = false;

  @override
  void initState() {
    super.initState();
    _scheduleAutoplay();
  }

  void _scheduleAutoplay() {
    _autoplay?.cancel();
    _autoplay = Timer(const Duration(seconds: 5), _advancePage);
  }

  void _advancePage() {
    if (!mounted || !controller.hasClients) return;
    controller.animateToPage(
      (page + 1) % _pageCount,
      duration: const Duration(milliseconds: 1150),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int value) {
    setState(() => page = value);
    _scheduleAutoplay();
  }

  void enterApp() => Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute<void>(builder: (_) => const HomeShell()));

  Future<void> signInWithGoogle() async {
    if (googleBusy) return;
    _autoplay?.cancel();
    setState(() => googleBusy = true);
    try {
      await googleAuth.signIn();
      if (mounted) enterApp();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => googleBusy = false);
        _scheduleAutoplay();
      }
    }
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          _StarField(controller: controller),
          _EarthPanorama(
            controller: controller,
            viewportWidth: constraints.maxWidth,
          ),
          const _EdgeVignette(),
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 28),
                  child: TickerlessWordmark(),
                ),
                Expanded(
                  child: NotificationListener<ScrollStartNotification>(
                    onNotification: (_) {
                      _autoplay?.cancel();
                      return false;
                    },
                    child: PageView(
                      controller: controller,
                      onPageChanged: _onPageChanged,
                      children: const [
                        _StoryPage(
                          eyebrow: 'LOOK CLOSER',
                          title: 'The world is\nthe stock market.',
                          body: 'Point at what you see.\nSearch what you’re curious about.\nOwn a piece of it.',
                          alignment: _CopyAlignment.lower,
                        ),
                        _StoryPage(
                          eyebrow: 'A MORE OPEN WORLD',
                          title: 'Same world.\nMore owners.',
                          body: 'The things you notice every day\ncan become part of your world.',
                          alignment: _CopyAlignment.upper,
                        ),
                        _StoryPage(
                          eyebrow: 'DISCOVER → OWN',
                          title: 'Turn attention\ninto ownership.',
                          body: 'Scan a product. Search an idea.\nPaste a link. Find the company\nbehind what caught your eye.',
                          alignment: _CopyAlignment.lower,
                        ),
                      ],
                    ),
                  ),
                ),
                _Dots(page: page),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
                  child: _AuthActions(
                    onEmail: enterApp,
                    onGoogle: googleBusy
                        ? null
                        : () => unawaited(signInWithGoogle()),
                    onGuest: enterApp,
                    googleBusy: googleBusy,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Real companies. Onchain. A more open world.',
                    style: TextStyle(
                      color: Color(0xFF71808A),
                      fontSize: 10,
                      letterSpacing: .15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _EarthPanorama extends StatelessWidget {
  const _EarthPanorama({required this.controller, required this.viewportWidth});

  final PageController controller;
  final double viewportWidth;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) {
      final position = controller.hasClients
          ? (controller.page ?? controller.initialPage.toDouble())
          : controller.initialPage.toDouble();
      return Transform.translate(
        offset: Offset(-position * viewportWidth, 0),
        child: child,
      );
    },
    child: OverflowBox(
      alignment: Alignment.centerLeft,
      maxWidth: viewportWidth * _pageCount,
      minWidth: viewportWidth * _pageCount,
      child: SizedBox(
        width: viewportWidth * _pageCount,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.white, Colors.white],
              stops: [0, .18, 1],
            ).createShader(bounds),
            child: Image.asset(
              'assets/images/earth-journey-v2.png',
              width: viewportWidth * _pageCount,
              fit: BoxFit.fitWidth,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    ),
  );
}

class _StarField extends StatelessWidget {
  const _StarField({required this.controller});

  final PageController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) {
      final position = controller.hasClients
          ? (controller.page ?? controller.initialPage.toDouble())
          : controller.initialPage.toDouble();
      return Transform.translate(
        offset: Offset(-position * 16, 0),
        child: child,
      );
    },
    child: const RepaintBoundary(
      child: CustomPaint(painter: _StarFieldPainter()),
    ),
  );
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(1709);
    for (var index = 0; index < 72; index++) {
      final x = random.nextDouble() * (size.width + 72);
      final y = 60 + random.nextDouble() * size.height * .68;
      final radius = .35 + random.nextDouble() * 1.05;
      final opacity = .18 + random.nextDouble() * .52;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EdgeVignette extends StatelessWidget {
  const _EdgeVignette();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.black.withValues(alpha: .12),
            Colors.transparent,
            Colors.black.withValues(alpha: .22),
            Colors.black,
          ],
          stops: const [0, .19, .43, .72, 1],
        ),
      ),
    ),
  );
}

enum _CopyAlignment { upper, lower }

class _StoryPage extends StatelessWidget {
  const _StoryPage({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.alignment,
  });

  final String eyebrow;
  final String title;
  final String body;
  final _CopyAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final upper = alignment == _CopyAlignment.upper;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upper) const SizedBox(height: 42) else const Spacer(),
          Text(
            eyebrow,
            style: const TextStyle(
              color: Color(0xFFAFC3CF),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              height: .92,
              fontWeight: FontWeight.w700,
              letterSpacing: -2.1,
            ),
          ),
          const SizedBox(height: 19),
          Container(
            width: 30,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
          if (upper) const Spacer() else const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      _pageCount,
      (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        width: index == page ? 24 : 5,
        height: 5,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: index == page ? Colors.white : const Color(0xFF31414A),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}

class _AuthActions extends StatelessWidget {
  const _AuthActions({
    required this.onEmail,
    required this.onGoogle,
    required this.onGuest,
    required this.googleBusy,
  });

  final VoidCallback onEmail;
  final VoidCallback? onGoogle;
  final VoidCallback onGuest;
  final bool googleBusy;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _AuthButton(
        label: 'Continue with email',
        icon: Icons.mail_outline_rounded,
        onPressed: onEmail,
        primary: true,
      ),
      const SizedBox(height: 10),
      _AuthButton(
        label: googleBusy ? 'Connecting to Google…' : 'Continue with Google',
        icon: Icons.g_mobiledata_rounded,
        onPressed: onGoogle,
      ),
      const SizedBox(height: 10),
      _AuthButton(
        label: 'Continue as guest',
        icon: Icons.arrow_forward_rounded,
        onPressed: onGuest,
      ),
    ],
  );
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: primary
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 19),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 19),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: .54),
              side: const BorderSide(color: Color(0xFF344955)),
            ),
          ),
  );
}
