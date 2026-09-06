import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'api_client.dart';

class GoogleAuthService {
  GoogleAuthService({TickerlessApi? api, FlutterSecureStorage? storage})
    : _api = api ?? TickerlessApi(),
      _storage = storage ?? const FlutterSecureStorage();

  static const _iosClientId =
      '322967876753-in0nbi712374ccro0614ngpq254tmdfl.apps.googleusercontent.com';
  static const _serverClientId =
      '322967876753-5cn9c50qlr0ffmbiq5ks30pir8cub2q8.apps.googleusercontent.com';
  static const _sessionKey = 'tickerless_session_token';

  final TickerlessApi _api;
  final FlutterSecureStorage _storage;
  bool _initialized = false;

  Future<AuthSession> signIn() async {
    final signIn = GoogleSignIn.instance;
    if (!_initialized) {
      await signIn.initialize(
        clientId: Platform.isIOS ? _iosClientId : null,
        serverClientId: _serverClientId,
      );
      _initialized = true;
    }
    if (!signIn.supportsAuthenticate()) {
      throw const ApiException('Google sign-in is unavailable on this device');
    }
    final account = await signIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const ApiException('Google did not return an identity token');
    }
    final session = await _api.googleLogin(idToken);
    await _storage.write(key: _sessionKey, value: session.accessToken);
    return session;
  }
}
