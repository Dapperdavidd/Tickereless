import 'package:flutter/material.dart';
import 'package:tickerless/core/theme/app_theme.dart';

/// A quiet brand frame while secure storage decides which door to open.
/// Returning users never see onboarding underneath the session restore.
class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.appGradient),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: .82, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Opacity(opacity: scale, child: child),
          ),
          child: Image.asset(
            'assets/images/tickerless-icon.png',
            width: 104,
            height: 104,
          ),
        ),
      ),
    ),
  );
}
