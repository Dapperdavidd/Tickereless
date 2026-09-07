import 'package:tickerless/core/error/exceptions.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/core/network/network_error.dart';
import 'package:tickerless/features/auth/data/datasource/auth_local_datasource.dart';
import 'package:tickerless/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:tickerless/features/auth/data/datasource/google_sign_in_datasource.dart';
import 'package:tickerless/features/auth/domain/entities/auth_session.dart';
import 'package:tickerless/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required GoogleSignInDataSource googleDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _googleDataSource = googleDataSource;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final GoogleSignInDataSource _googleDataSource;

  @override
  Future<AuthSession> signInWithEmail(String email, String password) =>
      _persist(() => _remoteDataSource.emailLogin(email, password));

  @override
  Future<AuthSession> registerWithEmail(String email, String password) =>
      _persist(() => _remoteDataSource.emailRegister(email, password));

  @override
  Future<AuthSession> signInWithGoogle() => _persist(() async {
    final idToken = await _googleDataSource.obtainIdToken();
    return _remoteDataSource.googleLogin(idToken);
  });

  @override
  Future<void> signOut() async {
    try {
      await _localDataSource.clearToken();
    } on LocalStorageException catch (error) {
      throw StorageFailure(error.message);
    }
  }

  /// Every sign-in path ends the same way: exchange for a session, cache the
  /// token, and translate whatever went wrong into an [AuthFailure].
  Future<AuthSession> _persist(Future<AuthSession> Function() exchange) async {
    try {
      final session = await exchange();
      await _localDataSource.cacheToken(session.accessToken);
      return session;
    } on ApiException catch (error) {
      throw AuthFailure(error.message);
    } on LocalStorageException catch (error) {
      throw StorageFailure(error.message);
    } catch (error) {
      throw AuthFailure(friendlyNetworkError(error));
    }
  }
}
