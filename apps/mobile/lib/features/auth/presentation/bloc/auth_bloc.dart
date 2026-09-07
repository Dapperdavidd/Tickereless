import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/features/auth/domain/entities/access_mode.dart';
import 'package:tickerless/features/auth/domain/entities/auth_session.dart';
import 'package:tickerless/features/auth/domain/usecases/register_with_email.dart';
import 'package:tickerless/features/auth/domain/usecases/restore_session.dart';
import 'package:tickerless/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:tickerless/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:tickerless/features/auth/domain/usecases/sign_out.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_event.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_state.dart';
import 'package:tickerless/features/wallet/domain/usecases/ensure_wallet.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignInWithEmailUseCase signInWithEmail,
    required RegisterWithEmailUseCase registerWithEmail,
    required SignInWithGoogleUseCase signInWithGoogle,
    required SignOutUseCase signOut,
    required EnsureWalletUseCase ensureWallet,
    required RestoreSessionUseCase restoreSession,
  }) : _signInWithEmail = signInWithEmail,
       _registerWithEmail = registerWithEmail,
       _signInWithGoogle = signInWithGoogle,
       _signOut = signOut,
       _ensureWallet = ensureWallet,
       _restoreSession = restoreSession,
       super(const AuthState()) {
    on<AuthRestoreRequested>(_onRestoreRequested);
    on<AuthGuestRequested>(_onGuestRequested);
    on<AuthEmailSubmitted>(_onEmailSubmitted);
    on<AuthGoogleRequested>(_onGoogleRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthErrorDismissed>(_onErrorDismissed);
    add(const AuthRestoreRequested());
  }

  final SignInWithEmailUseCase _signInWithEmail;
  final RegisterWithEmailUseCase _registerWithEmail;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOutUseCase _signOut;
  final EnsureWalletUseCase _ensureWallet;
  final RestoreSessionUseCase _restoreSession;

  Future<void> _onRestoreRequested(
    AuthRestoreRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final session = await _restoreSession();
      if (session == null) return;
      final wallet = await _ensureWallet(session.userId);
      emit(
        AuthState(
          mode: AccessMode.authenticated,
          session: session,
          walletAddress: wallet.address,
        ),
      );
    } on Failure {
      emit(const AuthState());
    }
  }

  void _onGuestRequested(AuthGuestRequested event, Emitter<AuthState> emit) {
    emit(const AuthState(mode: AccessMode.guest));
  }

  Future<void> _onEmailSubmitted(
    AuthEmailSubmitted event,
    Emitter<AuthState> emit,
  ) => _authenticate(
    emit,
    () => event.createAccount
        ? _registerWithEmail(event.email, event.password)
        : _signInWithEmail(event.email, event.password),
  );

  Future<void> _onGoogleRequested(
    AuthGoogleRequested event,
    Emitter<AuthState> emit,
  ) => _authenticate(emit, _signInWithGoogle.call);

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // A failed token wipe must not strand the user in a signed-in shell, so
    // the local state is cleared either way.
    try {
      await _signOut();
    } on Failure {
      // Nothing actionable to show: the session is gone from this session's
      // memory regardless.
    }
    emit(const AuthState());
  }

  void _onErrorDismissed(AuthErrorDismissed event, Emitter<AuthState> emit) {
    emit(state.copyWith(status: AuthStatus.idle));
  }

  /// Signing in is not finished until the account has a wallet: every screen
  /// behind the gate assumes an address exists.
  Future<void> _authenticate(
    Emitter<AuthState> emit,
    Future<AuthSession> Function() exchange,
  ) async {
    emit(state.copyWith(status: AuthStatus.inProgress));
    try {
      final session = await exchange();
      final wallet = await _ensureWallet(session.userId);
      emit(
        AuthState(
          mode: AccessMode.authenticated,
          session: session,
          walletAddress: wallet.address,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
        ),
      );
    }
  }
}
