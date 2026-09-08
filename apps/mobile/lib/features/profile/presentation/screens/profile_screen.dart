import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/theme/appearance_controller.dart';
import 'package:tickerless/core/widgets/hairline_list.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_event.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_state.dart';
import 'package:tickerless/features/auth/presentation/widgets/sign_in_sheet.dart';
import 'package:tickerless/features/portfolio/presentation/widgets/tab_list.dart';
import 'package:tickerless/features/profile/data/profile_identity_store.dart';
import 'package:tickerless/features/profile/presentation/widgets/private_key_dialogs.dart';
import 'package:tickerless/features/profile/presentation/widgets/profile_avatar.dart';
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
        onPressed: () => showSignInSheet(context),
        child: const Text('Sign in or create account'),
      ),
    ],
  );
}

class _AccountProfile extends StatefulWidget {
  const _AccountProfile({required this.state});
  final AuthState state;

  @override
  State<_AccountProfile> createState() => _AccountProfileState();
}

class _AccountProfileState extends State<_AccountProfile> {
  final _store = ProfileIdentityStore();
  ProfileIdentity? _identity;

  AuthState get state => widget.state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = state.session;
    if (session == null) return;
    final identity = await _store.read(session.userId, session.email);
    if (mounted) setState(() => _identity = identity);
  }

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
            GestureDetector(
              onTap: userId == null
                  ? null
                  : () => _editProfile(context, userId),
              child: ProfileAvatar(
                index: _identity?.avatar ?? 0,
                photoPath: _identity?.photoPath,
                size: 62,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _identity?.name ??
                        state.session?.email.split('@').first ??
                        'Explorer',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    state.session?.email ?? '',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    shortAddress ?? 'Preparing wallet…',
                    style: const TextStyle(color: AppColors.blue, fontSize: 11),
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
              icon: Icons.edit_outlined,
              label: 'Edit profile',
              detail: 'Name, avatar, and photo',
              onTap: userId == null
                  ? null
                  : () => _editProfile(context, userId),
            ),
            SettingTile(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Your Wallet',
              detail: shortAddress,
              onTap: address == null
                  ? null
                  : () => _showWallet(context, address),
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
            SettingTile(
              icon: Icons.notifications_none,
              label: 'Notifications',
              detail: AppearanceController().newsNotifications
                  ? 'Company news · On'
                  : 'Off',
              onTap: () => _notifications(context),
            ),
            SettingTile(
              icon: Icons.dark_mode_outlined,
              label: 'Appearance',
              detail: AppearanceController().themeMode == ThemeMode.light
                  ? 'Light'
                  : 'Dark',
              onTap: () => _appearance(context),
            ),
            SettingTile(
              icon: Icons.help_outline,
              label: 'Help & Support',
              onTap: () => _info(
                context,
                'Help & Support',
                'Tickerless currently runs on Base Sepolia. For account or wallet help, never share your private key. Support channels will be added before public release.',
              ),
            ),
            SettingTile(
              icon: Icons.info_outline,
              label: 'About Tickerless',
              onTap: () => _info(
                context,
                'About Tickerless',
                'Point at the world. Search it. Own a piece of it.\n\nTickerless connects products, companies, live company news, and test tokenized equities settled with testnet USDC on Base Sepolia.',
              ),
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
                'Base Sepolia · Live testnet',
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

  Future<void> _editProfile(BuildContext context, String userId) async {
    final current =
        _identity ?? await _store.read(userId, state.session!.email);
    if (!context.mounted) return;
    final controller = TextEditingController(text: current.name);
    var avatar = current.avatar;
    var photoPath = current.photoPath;
    final saved = await showModalBottomSheet<ProfileIdentity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceRaised,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            24,
            22,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your profile',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Choose an avatar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 13,
                  runSpacing: 13,
                  children: [
                    for (var index = 0; index < 6; index++)
                      GestureDetector(
                        onTap: () => setSheetState(() {
                          avatar = index;
                          photoPath = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: photoPath == null && avatar == index
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ProfileAvatar(index: index, size: 48),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () async {
                    final path = await _store.pickPhoto(userId);
                    if (path != null) setSheetState(() => photoPath = path);
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose photo from device'),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    sheetContext,
                    ProfileIdentity(
                      name: controller.text.trim().isEmpty
                          ? current.name
                          : controller.text.trim(),
                      avatar: avatar,
                      photoPath: photoPath,
                    ),
                  ),
                  child: const Text('Save profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
    if (saved == null) return;
    await _store.save(userId, saved);
    if (mounted) setState(() => _identity = saved);
  }

  Future<void> _showWallet(
    BuildContext context,
    String address,
  ) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Your wallet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wallet address',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SelectableText(address),
          const SizedBox(height: 18),
          const Text(
            'This wallet is stored securely on this iPhone. It will not automatically appear on another device. Export your private key before changing phones or deleting the app.',
            style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: address));
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text('Copy address'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Done'),
        ),
      ],
    ),
  );

  Future<void> _info(BuildContext context, String title, String body) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );

  Future<void> _appearance(BuildContext context) async {
    final controller = AppearanceController();
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Appearance',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              RadioGroup<ThemeMode>(
                groupValue: controller.themeMode,
                onChanged: (value) => Navigator.pop(context, value),
                child: const Column(
                  children: [
                    RadioListTile(
                      value: ThemeMode.dark,
                      title: Text('Dark'),
                      subtitle: Text('Deep space and blue light'),
                    ),
                    RadioListTile(
                      value: ThemeMode.light,
                      title: Text('Light'),
                      subtitle: Text('White canvas with a blue atmosphere'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) await controller.setThemeMode(selected);
  }

  Future<void> _notifications(BuildContext context) async {
    final controller = AppearanceController();
    final enabled = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          value: controller.newsNotifications,
          title: const Text('Company news alerts'),
          subtitle: const Text(
            'Save your preference now. Device push delivery will be enabled when the production notification service is connected.',
          ),
          onChanged: (value) => Navigator.pop(context, value),
        ),
      ),
    );
    if (enabled != null) await controller.setNewsNotifications(enabled);
  }
}
