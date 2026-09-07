import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Explore without an account. Discovery works; purchasing does not.
class AuthGuestRequested extends AuthEvent {
  const AuthGuestRequested();
}

class AuthEmailSubmitted extends AuthEvent {
  const AuthEmailSubmitted({
    required this.email,
    required this.password,
    required this.createAccount,
  });

  final String email;
  final String password;
  final bool createAccount;

  @override
  List<Object?> get props => [email, password, createAccount];
}

class AuthGoogleRequested extends AuthEvent {
  const AuthGoogleRequested();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Clears a failure message once the screen has shown it.
class AuthErrorDismissed extends AuthEvent {
  const AuthErrorDismissed();
}
