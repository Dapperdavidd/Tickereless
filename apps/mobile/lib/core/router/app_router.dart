import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/router/router_refresh.dart';
import 'package:tickerless/features/activity/presentation/screens/activity_screen.dart';
import 'package:tickerless/features/activity/presentation/screens/currency_asset_screen.dart';
import 'package:tickerless/features/auth/domain/entities/access_mode.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_state.dart';
import 'package:tickerless/features/auth/presentation/screens/email_auth_screen.dart';
import 'package:tickerless/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:tickerless/features/auth/presentation/screens/startup_screen.dart';
import 'package:tickerless/features/discovery/presentation/screens/lens_screen.dart';
import 'package:tickerless/features/discovery/presentation/screens/link_screen.dart';
import 'package:tickerless/features/discovery/presentation/screens/passport_screen.dart';
import 'package:tickerless/features/discovery/presentation/screens/search_screen.dart';
import 'package:tickerless/features/home/presentation/screens/discover_screen.dart';
import 'package:tickerless/features/home/presentation/screens/home_shell.dart';
import 'package:tickerless/features/portfolio/presentation/screens/purchase_confirmed_screen.dart';
import 'package:tickerless/features/portfolio/presentation/screens/purchase_screen.dart';
import 'package:tickerless/features/portfolio/presentation/screens/world_screen.dart';
import 'package:tickerless/features/profile/presentation/screens/profile_screen.dart';

/// Every route path in the app, in one place.
abstract final class AppRoutes {
  static const startup = '/';
  static const onboarding = '/onboarding';
  static const emailAuth = '/email-auth';
  static const discover = '/discover';
  static const world = '/world';
  static const activity = '/activity';
  static const currencyAsset = '/currency-asset';
  static const profile = '/profile';
  static const search = '/search';
  static const lens = '/lens';
  static const link = '/link';
  static const passport = '/passport';
  static const purchase = '/purchase';
  static const receipt = '/receipt';
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Built with the [AuthBloc] rather than as a top-level constant, because the
/// gate below has to read live access state.
GoRouter createAppRouter(AuthBloc authBloc) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.startup,
  refreshListenable: GoRouterRefreshStream(authBloc.stream),
  // Onboarding is the only way past the door. It is enforced here rather than
  // by whichever screen happens to be first, because "first" is not something
  // the app controls once deep links exist.
  redirect: (context, state) {
    final restoring = authBloc.state.status == AuthStatus.restoring;
    if (restoring) {
      return state.matchedLocation == AppRoutes.startup
          ? null
          : AppRoutes.startup;
    }
    final signedOut = authBloc.state.mode == AccessMode.signedOut;
    final authenticated = authBloc.state.mode == AccessMode.authenticated;
    final atDoor =
        state.matchedLocation == AppRoutes.onboarding ||
        state.matchedLocation == AppRoutes.emailAuth;

    if (state.matchedLocation == AppRoutes.startup) {
      return signedOut ? AppRoutes.onboarding : AppRoutes.discover;
    }
    if (signedOut && !atDoor) return AppRoutes.onboarding;
    if (!signedOut && state.matchedLocation == AppRoutes.onboarding) {
      return AppRoutes.discover;
    }
    if (authenticated && state.matchedLocation == AppRoutes.emailAuth) {
      return AppRoutes.discover;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.startup,
      builder: (context, state) => const StartupScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.emailAuth,
      builder: (context, state) => const EmailAuthScreen(),
    ),
    // The three tabs keep their own navigation stacks, so switching tabs does
    // not throw away where the user was in the other one.
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomeShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.discover,
              builder: (context, state) => const DiscoverScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.world,
              builder: (context, state) => const WorldScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.activity,
              builder: (context, state) => const ActivityScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.currencyAsset,
      builder: (context, state) =>
          CurrencyAssetScreen(args: state.extra! as CurrencyAssetArgs),
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.lens,
      builder: (context, state) => const LensScreen(),
    ),
    GoRoute(
      path: AppRoutes.link,
      builder: (context, state) => const LinkScreen(),
    ),
    GoRoute(
      path: AppRoutes.passport,
      builder: (context, state) =>
          PassportScreen(args: state.extra! as PassportArgs),
    ),
    GoRoute(
      path: AppRoutes.purchase,
      builder: (context, state) =>
          PurchaseScreen(args: state.extra! as PurchaseArgs),
    ),
    GoRoute(
      path: AppRoutes.receipt,
      builder: (context, state) =>
          PurchaseConfirmedScreen(args: state.extra! as ReceiptArgs),
    ),
  ],
);
