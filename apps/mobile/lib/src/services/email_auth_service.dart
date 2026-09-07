import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

class EmailAuthService {
  EmailAuthService({TickerlessApi? api, FlutterSecureStorage? storage})
    : _api = api ?? TickerlessApi(),
      _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'tickerless_session_token';
  final TickerlessApi _api;
  final FlutterSecureStorage _storage;

  Future<AuthSession> signIn(String email, String password) async {
    final session = await _api.emailLogin(email, password);
    await _persist(session);
    return session;
  }

  Future<AuthSession> createAccount(String email, String password) async {
    final session = await _api.emailRegister(email, password);
    await _persist(session);
    return session;
  }

  Future<void> _persist(AuthSession session) =>
      _storage.write(key: _sessionKey, value: session.accessToken);
}
