import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:tickerless/core/error/exceptions.dart';

/// Wraps the Google plugin so the repository only ever deals in ID tokens.
abstract interface class GoogleSignInDataSource {
  /// The Google identity token to exchange with our backend.
  Future<String> obtainIdToken();
}

class GoogleSignInDataSourceImpl implements GoogleSignInDataSource {
  GoogleSignInDataSourceImpl();

  static const _iosClientId =
      '322967876753-in0nbi712374ccro0614ngpq254tmdfl.apps.googleusercontent.com';
  static const _serverClientId =
      '322967876753-5cn9c50qlr0ffmbiq5ks30pir8cub2q8.apps.googleusercontent.com';

  bool _initialized = false;

  @override
  Future<String> obtainIdToken() async {
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
    return idToken;
  }
}
