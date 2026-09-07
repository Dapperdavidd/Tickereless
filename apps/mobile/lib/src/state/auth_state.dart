import 'package:flutter/foundation.dart';

import '../services/api_client.dart';

final authState = AuthState();

enum AccessMode { signedOut, guest, authenticated }

class AuthState extends ChangeNotifier {
  AccessMode _mode = AccessMode.signedOut;
  AuthSession? _session;

  AccessMode get mode => _mode;
  AuthSession? get session => _session;
  bool get isGuest => _mode == AccessMode.guest;
  bool get canPurchase => _mode == AccessMode.authenticated;

  void continueAsGuest() {
    _session = null;
    _mode = AccessMode.guest;
    notifyListeners();
  }

  void authenticate(AuthSession session) {
    _session = session;
    _mode = AccessMode.authenticated;
    notifyListeners();
  }

  void signOut() {
    _session = null;
    _mode = AccessMode.signedOut;
    notifyListeners();
  }
}
