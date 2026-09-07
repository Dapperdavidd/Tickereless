import 'package:flutter/material.dart';

/// The three ways into the app, in the order we want them chosen.
class AuthActions extends StatelessWidget {
  const AuthActions({
    required this.onEmail,
    required this.onGoogle,
    required this.onGuest,
    required this.googleBusy,
    super.key,
  });

  final VoidCallback onEmail;
  final VoidCallback? onGoogle;
  final VoidCallback onGuest;
  final bool googleBusy;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _AuthButton(
        label: 'Continue with email',
        icon: Icons.mail_outline_rounded,
        onPressed: onEmail,
        primary: true,
      ),
      const SizedBox(height: 10),
      _AuthButton(
        label: googleBusy ? 'Connecting to Google…' : 'Continue with Google',
        icon: Icons.g_mobiledata_rounded,
        onPressed: onGoogle,
      ),
      const SizedBox(height: 10),
      _AuthButton(
        label: 'Continue as guest',
        icon: Icons.arrow_forward_rounded,
        onPressed: onGuest,
      ),
    ],
  );
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: primary
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 19),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 19),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: .54),
              side: const BorderSide(color: Color(0xFF344955)),
            ),
          ),
  );
}
