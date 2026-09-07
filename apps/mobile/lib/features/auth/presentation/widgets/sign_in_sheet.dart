import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/features/auth/domain/entities/access_mode.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_event.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_state.dart';

Future<void> showSignInSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: const _SignInSheet(),
      ),
    );

class _SignInSheet extends StatelessWidget {
  const _SignInSheet();

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthBloc, AuthState>(
    listenWhen: (previous, current) =>
        previous.mode != current.mode ||
        previous.errorMessage != current.errorMessage,
    listener: (context, state) {
      if (state.mode == AccessMode.authenticated) Navigator.of(context).pop();
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        context.read<AuthBloc>().add(const AuthErrorDismissed());
      }
    },
    builder: (context, state) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Make it yours.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in or create an account to activate your wallet and keep your world.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 26),
          FilledButton.icon(
            onPressed: state.isBusy
                ? null
                : () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.emailAuth);
                  },
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text('Continue with email'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: state.isBusy
                ? null
                : () =>
                      context.read<AuthBloc>().add(const AuthGoogleRequested()),
            icon: const Icon(Icons.g_mobiledata_rounded),
            label: Text(
              state.isBusy ? 'Connecting to Google…' : 'Continue with Google',
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Google automatically signs you in if the account exists, or creates it if it is new.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    ),
  );
}
