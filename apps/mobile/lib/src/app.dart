import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

class TickerlessApp extends StatelessWidget {
  const TickerlessApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Tickerless',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const OnboardingScreen(),
  );
}
