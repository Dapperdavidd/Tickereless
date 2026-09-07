import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/widgets/tickerless_wordmark.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_event.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_state.dart';
import 'package:tickerless/features/auth/presentation/widgets/auth_actions.dart';
import 'package:tickerless/features/auth/presentation/widgets/consent_text.dart';
import 'package:tickerless/features/auth/presentation/widgets/onboarding_backdrop.dart';
import 'package:tickerless/features/auth/presentation/widgets/onboarding_story_page.dart';
import 'package:tickerless/features/auth/presentation/widgets/page_dots.dart';

const _pageCount = 3;

/// The way in: a three-page story over one continuous world, with the access
/// choices pinned underneath.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController(keepPage: false);
  Timer? _autoplay;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _scheduleAutoplay();
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoplay() {
    _autoplay?.cancel();
    _autoplay = Timer(const Duration(milliseconds: 3300), _advancePage);
  }

  Future<void> _advancePage() async {
    if (!mounted || !_controller.hasClients) return;
    await _controller.animateToPage(
      (_page + 1) % _pageCount,
      // The wrap back to the first page travels three screens, so it gets a
      // little longer to do it.
      duration: Duration(milliseconds: _page == _pageCount - 1 ? 900 : 760),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int value) {
    setState(() => _page = value);
    _scheduleAutoplay();
  }

  void _openEmail() {
    _autoplay?.cancel();
    context.push(AppRoutes.emailAuth).then((_) {
      if (mounted) _scheduleAutoplay();
    });
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthBloc, AuthState>(
    listenWhen: (previous, current) =>
        previous.status != current.status &&
        current.status == AuthStatus.failure,
    listener: (context, state) {
      _scheduleAutoplay();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? 'Sign-in failed')),
      );
      context.read<AuthBloc>().add(const AuthErrorDismissed());
    },
    builder: (context, state) => Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            OnboardingBackdrop(
              controller: _controller,
              viewportWidth: constraints.maxWidth,
              pageCount: _pageCount,
            ),
            SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 28),
                    child: TickerlessWordmark(),
                  ),
                  Expanded(
                    child: NotificationListener<ScrollStartNotification>(
                      // A deliberate swipe wins over the autoplay timer.
                      onNotification: (_) {
                        _autoplay?.cancel();
                        return false;
                      },
                      child: PageView(
                        controller: _controller,
                        onPageChanged: _onPageChanged,
                        children: const [
                          OnboardingStoryPage(
                            eyebrow: 'LOOK CLOSER',
                            title: 'The world is\nthe stock market.',
                            body: 'Point at what you see.\nSearch what you’re curious about.\nOwn a piece of it.',
                          ),
                          OnboardingStoryPage(
                            eyebrow: 'A MORE OPEN WORLD',
                            title: 'Same world.\nMore owners.',
                            body: 'The things you notice every day\ncan become part of your world.',
                          ),
                          OnboardingStoryPage(
                            eyebrow: 'DISCOVER → OWN',
                            title: 'Turn attention\ninto ownership.',
                            body: '',
                            showMethods: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  PageDots(page: _page, count: _pageCount),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                    child: AuthActions(
                      googleBusy: state.isBusy,
                      onEmail: _openEmail,
                      onGoogle: state.isBusy
                          ? null
                          : () {
                              _autoplay?.cancel();
                              context.read<AuthBloc>().add(
                                const AuthGoogleRequested(),
                              );
                            },
                      onGuest: () => context.read<AuthBloc>().add(
                        const AuthGuestRequested(),
                      ),
                    ),
                  ),
                  const ConsentText(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
