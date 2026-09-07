import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/tickerless_wordmark.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_event.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_state.dart';

/// Sign in or create an account. One form, two modes — the copy and the
/// autofill hints switch, the fields do not.
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _createAccount = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthEmailSubmitted(
        email: _emailController.text,
        password: _passwordController.text,
        createAccount: _createAccount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) => Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const SizedBox(height: 24),
            const TickerlessWordmark(),
            const SizedBox(height: 64),
            Text(
              _createAccount ? 'Create your world.' : 'Welcome back.',
              style: const TextStyle(
                fontSize: 42,
                height: .94,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _createAccount
                  ? 'Start discovering what is behind the things you notice.'
                  : 'Continue where your curiosity left off.',
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 34),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      return email.contains('@') && email.contains('.')
                          ? null
                          : 'Enter a valid email address';
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: _createAccount
                        ? const [AutofillHints.newPassword]
                        : const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => (value?.length ?? 0) >= 10
                        ? null
                        : 'Password must be at least 10 characters',
                  ),
                ],
              ),
            ),
            if (state.status == AuthStatus.failure &&
                state.errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                state.errorMessage!,
                style: const TextStyle(color: AppColors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: state.isBusy ? null : _submit,
              child: Text(
                state.isBusy
                    ? 'Please wait…'
                    : _createAccount
                    ? 'Create account'
                    : 'Continue with email',
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: state.isBusy
                  ? null
                  : () {
                      setState(() => _createAccount = !_createAccount);
                      context.read<AuthBloc>().add(const AuthErrorDismissed());
                    },
              child: Text(
                _createAccount
                    ? 'Already have an account? Sign in'
                    : 'New to Tickerless? Create an account',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
