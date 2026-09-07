import 'package:tickerless/core/network/api_client.dart';
import 'package:tickerless/features/auth/data/model/auth_session_model.dart';

/// The backend's auth endpoints.
abstract interface class AuthRemoteDataSource {
  Future<AuthSessionModel> emailLogin(String email, String password);
  Future<AuthSessionModel> emailRegister(String email, String password);
  Future<AuthSessionModel> googleLogin(String idToken);
  Future<AuthSessionModel> restoreSession(String accessToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({ApiClient? client})
    : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<AuthSessionModel> emailLogin(String email, String password) =>
      _emailAuth('/v1/auth/email/login', email, password);

  @override
  Future<AuthSessionModel> emailRegister(String email, String password) =>
      _emailAuth('/v1/auth/email/register', email, password);

  @override
  Future<AuthSessionModel> googleLogin(String idToken) async {
    final decoded = await _client.postJson('/v1/auth/google', {
      'id_token': idToken,
    }, fallbackError: 'Google sign-in failed');
    return AuthSessionModel.fromJson(decoded);
  }

  @override
  Future<AuthSessionModel> restoreSession(String accessToken) async {
    final user = await _client.getJson(
      '/v1/auth/me',
      bearerToken: accessToken,
      fallbackError: 'Could not restore your session',
    );
    return AuthSessionModel.fromUser(user, accessToken);
  }

  Future<AuthSessionModel> _emailAuth(
    String path,
    String email,
    String password,
  ) async {
    final decoded = await _client.postJson(path, {
      'email': email.trim(),
      'password': password,
    }, fallbackError: 'Email authentication failed');
    return AuthSessionModel.fromJson(decoded);
  }
}
