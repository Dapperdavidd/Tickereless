import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/tickerless_wordmark.dart';
import 'home_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  void _enterApp() => Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute<void>(builder: (_) => const HomeShell()));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 12),
              child: TickerlessWordmark(),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: const [
                  _OnboardingPage(
                    title: 'The world is the stock market.',
                    description: 'Point at what you see. Search what you’re curious about. Own a piece of it.',
                  ),
                  _OnboardingPage(
                    title: 'Turn curiosity into ownership.',
                    description: 'Scan products, search naturally, or paste a link. No tickers required.',
                    icon: Icons.travel_explore_rounded,
                  ),
                  _OnboardingPage(
                    title: 'Same world. More owners.',
                    description: 'From everyday attention to onchain ownership—built on Base Sepolia.',
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: index == _page ? 22 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: index == _page ? Colors.white : AppColors.border,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _enterApp,
              child: const Text('Create Account'),
            ),
            const SizedBox(height: 10),
            const Text(
              'or continue with',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AuthButton(
                  icon: Icons.apple,
                  label: 'Apple',
                  onTap: _enterApp,
                ),
                const SizedBox(width: 12),
                _AuthButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Google',
                  onTap: _enterApp,
                ),
                const SizedBox(width: 12),
                _AuthButton(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  onTap: _enterApp,
                ),
              ],
            ),
            TextButton(
              onPressed: _enterApp,
              child: const Text('Continue as guest'),
            ),
            const Text(
              'Authentication comes later. Every option enters the demo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 9),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.description,
    this.icon,
  });

  final String title;
  final String description;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(
        child: Center(
          child: icon == null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/earth-onboarding.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                )
              : Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceRaised,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(icon, size: 54, color: AppColors.blue),
                ),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 38,
            height: 0.98,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.6,
          ),
        ),
      ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          description,
          style: const TextStyle(
            color: Color(0xFFD7E2E8),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Continue with $label',
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 58,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 27),
      ),
    ),
  );
}
