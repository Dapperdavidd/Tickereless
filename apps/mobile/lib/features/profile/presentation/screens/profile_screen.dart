import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/hairline_list.dart';
import 'package:tickerless/core/widgets/space_orb.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_event.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_state.dart';
import 'package:tickerless/features/portfolio/presentation/widgets/tab_list.dart';
import 'package:tickerless/features/profile/presentation/widgets/private_key_dialogs.dart';
import 'package:tickerless/features/profile/presentation/widgets/setting_tile.dart';
import 'package:tickerless/features/wallet/domain/entities/wallet_identity.dart';
import 'package:tickerless/features/wallet/domain/usecases/reveal_private_key.dart';

/// Who the user is in the ownership layer — or an invitation to become
/// someone, if they are still a guest.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) =>
          state.isGuest ? const _GuestProfile() : _AccountProfile(state: state),
    ),
  );
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) => TabList(
    title: 'You',
    subtitle: 'You are exploring without a profile.',
    children: [
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_outline_rounded, size: 32),
          SizedBox(height: 16),
          Text(
            'Guest mode',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 7),
          Text(
            'Search, scan, and discover freely. Sign in when you are ready '
            'to own test assets and create your profile.',
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          SizedBox(height: 26),
        ],
      ),
      FilledButton(
        onPressed: () => context.push(AppRoutes.emailAuth),
        child: const Text('Sign in or create account'),
      ),
    ],
  );
}

class _AccountProfile extends StatelessWidget {
  const _AccountProfile({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final address = state.walletAddress;
    final shortAddress = address == null
        ? null
        : WalletIdentity(address: address).shortAddress;
    final userId = state.session?.userId;

    return TabList(
      title: 'You',
      subtitle: 'Your identity in the ownership layer.',
      children: [
        Row(
          children: [
            const SpaceOrb(size: 62),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.session?.email ?? 'Explorer',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    shortAddress ?? 'Preparing wallet…',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        HairlineList(
          children: [
            SettingTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Your Wallet',
              detail: shortAddress,
            ),
            SettingTile(
              icon: Icons.key_outlined,
              label: 'View private key',
              onTap: userId == null
                  ? null
                  : () => revealPrivateKey(
                      context,
                      revealUseCase: context.read<RevealPrivateKeyUseCase>(),
                      userId: userId,
                    ),
            ),
            const SettingTile(
              icon: Icons.notifications_none,
              label: 'Notifications',
            ),
            const SettingTile(
              icon: Icons.dark_mode_outlined,
              label: 'Appearance · Dark',
            ),
            const SettingTile(
              icon: Icons.help_outline,
              label: 'Help & Support',
            ),
            const SettingTile(
              icon: Icons.info_outline,
              label: 'About Tickerless',
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.blue, size: 17),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Base Sepolia · Demo assets',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          // The router's gate sends a signed-out user back to onboarding, so
          // this does not have to unwind the stack itself.
          onPressed: () =>
              context.read<AuthBloc>().add(const AuthSignOutRequested()),
          child: const Text('Sign Out'),
        ),
      ],
    );
  }
}
