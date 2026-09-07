import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/di/dependencies.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tickerless/features/discovery/presentation/bloc/lens_bloc.dart';
import 'package:tickerless/features/discovery/presentation/bloc/link_bloc.dart';
import 'package:tickerless/features/discovery/presentation/bloc/search_bloc.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_bloc.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_event.dart';

/// Wires dependencies to blocs to the router. Everything below this is a
/// feature; everything above it is `main`.
class TickerlessApp extends StatefulWidget {
  TickerlessApp({AppDependencies? dependencies, super.key})
    : dependencies = dependencies ?? AppDependencies();

  final AppDependencies dependencies;

  @override
  State<TickerlessApp> createState() => _TickerlessAppState();
}

class _TickerlessAppState extends State<TickerlessApp> {
  late final AuthBloc _authBloc = AuthBloc(
    signInWithEmail: widget.dependencies.signInWithEmail,
    registerWithEmail: widget.dependencies.registerWithEmail,
    signInWithGoogle: widget.dependencies.signInWithGoogle,
    signOut: widget.dependencies.signOut,
    ensureWallet: widget.dependencies.ensureWallet,
  );

  late final GoRouter _router = createAppRouter(_authBloc);

  @override
  void dispose() {
    _authBloc.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;

    return MultiRepositoryProvider(
      providers: [
        // Exposed to the profile screen, which reveals the key in a dialog
        // rather than holding it in any bloc state.
        RepositoryProvider.value(value: dependencies.revealPrivateKey),
        // The passport builds its own bloc per company, so it reads these
        // rather than receiving a bloc from up here.
        RepositoryProvider.value(value: dependencies.getPriceSeries),
        RepositoryProvider.value(value: dependencies.getCompanyNews),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider(
            create: (context) => PortfolioBloc(
              getPositions: dependencies.getPositions,
              recordPurchase: dependencies.recordPurchase,
            )..add(const PortfolioRequested()),
          ),
          BlocProvider(
            create: (context) =>
                SearchBloc(searchCompanies: dependencies.searchCompanies),
          ),
          BlocProvider(
            create: (context) =>
                LinkBloc(resolveLink: dependencies.resolveLink),
          ),
          BlocProvider(
            create: (context) => LensBloc(
              recognizeFrame: dependencies.recognizeFrame,
              recognizeText: dependencies.recognizeText,
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'Tickerless',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          routerConfig: _router,
        ),
      ),
    );
  }
}
