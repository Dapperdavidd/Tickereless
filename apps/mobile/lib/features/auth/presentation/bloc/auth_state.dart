import 'package:equatable/equatable.dart';
import 'package:tickerless/features/auth/domain/entities/access_mode.dart';
import 'package:tickerless/features/auth/domain/entities/auth_session.dart';

enum AuthStatus { idle, inProgress, failure }

/// Access is one long-lived fact (who is here) plus a transient one (is a
/// sign-in in flight), so this is a single state object rather than a set of
/// classes — the screens read `mode` and `status` independently.
class AuthState extends Equatable {
  const AuthState({
    this.mode = AccessMode.signedOut,
    this.status = AuthStatus.idle,
    this.session,
    this.walletAddress,
    this.errorMessage,
  });

  final AccessMode mode;
  final AuthStatus status;
  final AuthSession? session;
  final String? walletAddress;
  final String? errorMessage;

  bool get isGuest => mode.isGuest;
  bool get canPurchase => mode.canPurchase;
  bool get isBusy => status == AuthStatus.inProgress;

  AuthState copyWith({
    AccessMode? mode,
    AuthStatus? status,
    AuthSession? session,
    String? walletAddress,
    String? errorMessage,
  }) => AuthState(
    mode: mode ?? this.mode,
    status: status ?? this.status,
    session: session ?? this.session,
    walletAddress: walletAddress ?? this.walletAddress,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    mode,
    status,
    session,
    walletAddress,
    errorMessage,
  ];
}
