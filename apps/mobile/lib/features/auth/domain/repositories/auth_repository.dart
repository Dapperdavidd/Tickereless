import 'package:tickerless/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> signInWithEmail(String email, String password);
  Future<AuthSession> registerWithEmail(String email, String password);
  Future<AuthSession> signInWithGoogle();
  Future<AuthSession?> restoreSession();

  /// Drops the persisted session token from this device.
  Future<void> signOut();
}
