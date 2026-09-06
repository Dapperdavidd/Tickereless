import 'dart:async';

import 'package:flutter/material.dart';

import '../services/google_auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tickerless_wordmark.dart';
import 'home_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  final googleAuth = GoogleAuthService();
  int page = 0;
  bool googleBusy = false;

  void enterApp() => Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute<void>(builder: (_) => const HomeShell()));

  Future<void> signInWithGoogle() async {
    if (googleBusy) return;
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
      if (mounted) setState(() => googleBusy = false);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 30, bottom: 10),
            child: TickerlessWordmark(),
          ),
          Expanded(
            child: PageView(
              controller: controller,
              onPageChanged: (value) => setState(() => page = value),
              children: const [
                _WorldPage(
                  title: 'The world is the stock market.',
                  body: 'Point at what you see.\nSearch what you’re curious about.\nOwn a piece of it.',
                ),
                _HowItWorksPage(),
                _WorldPage(
                  title: 'Same\nworld.\nMore\nowners.',
                  body: 'From everyday attention\nto onchain ownership.',
                  imageBelow: true,
                ),
              ],
            ),
          ),
          _Dots(page: page),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
            child: _AuthActions(
              onEnter: enterApp,
              onGoogle: googleBusy ? null : () => unawaited(signInWithGoogle()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: Text(
              'Real companies. Onchain. A more open world.',
              style: TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ),
        ],
      ),
    ),
  );
}

class _WorldPage extends StatelessWidget {
  const _WorldPage({
    required this.title,
    required this.body,
    this.imageBelow = false,
  });
  final String title;
  final String body;
  final bool imageBelow;

  @override
  Widget build(BuildContext context) {
    final image = Expanded(
      flex: imageBelow ? 5 : 6,
      child: Image.asset(
        'assets/images/earth-onboarding.png',
        width: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
      ),
    );
    final copy = Padding(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 285,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 40,
                height: .91,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.8,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(width: 28, height: 2, color: Colors.white),
          const SizedBox(height: 18),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFFD8E1E6),
            ),
          ),
        ],
      ),
    );
    return Column(children: imageBelow ? [copy, image] : [image, copy]);
  }
}

class _HowItWorksPage extends StatelessWidget {
  const _HowItWorksPage();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(24, 38, 24, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Turn curiosity\ninto ownership.',
          style: TextStyle(
            fontSize: 34,
            height: .95,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.4,
          ),
        ),
        SizedBox(height: 30),
        _Method(
          icon: Icons.camera_alt_outlined,
          title: 'Scan anything',
          subtitle: 'Products, logos, receipts',
        ),
        _Method(
          icon: Icons.search,
          title: 'Search naturally',
          subtitle: 'No tickers needed',
        ),
        _Method(
          icon: Icons.link,
          title: 'Paste a link',
          subtitle: 'Articles, websites, anything',
        ),
        Spacer(),
        Text(
          'Four Coinbase Tokenized Stocks.\nOne world of ways to discover them.',
          style: TextStyle(color: AppColors.muted, height: 1.45, fontSize: 12),
        ),
      ],
    ),
  );
}

class _Method extends StatelessWidget {
  const _Method({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, size: 25),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.page});
  final int page;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      3,
      (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: index == page ? 18 : 5,
        height: 5,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: index == page ? Colors.white : AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}

class _AuthActions extends StatelessWidget {
  const _AuthActions({required this.onEnter, required this.onGoogle});
  final VoidCallback onEnter;
  final VoidCallback? onGoogle;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      FilledButton(onPressed: onEnter, child: const Text('Create Account')),
      const SizedBox(height: 8),
      const Text(
        'Or continue with',
        style: TextStyle(color: AppColors.muted, fontSize: 10),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AuthButton(
            label: 'Google',
            icon: Icons.g_mobiledata,
            onTap: onGoogle,
          ),
          const SizedBox(width: 14),
          _AuthButton(label: 'Email', icon: Icons.mail_outline, onTap: onEnter),
        ],
      ),
      SizedBox(
        height: 28,
        child: TextButton(
          onPressed: onEnter,
          child: const Text(
            'Continue as guest',
            style: TextStyle(fontSize: 11),
          ),
        ),
      ),
    ],
  );
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Continue with $label',
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 50,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, size: 24),
      ),
    ),
  );
}
