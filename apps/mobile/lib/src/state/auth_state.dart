import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import '../services/wallet_service.dart';

final authState = AuthState();

enum AccessMode { signedOut, guest, authenticated }

class AuthState extends ChangeNotifier {
  AccessMode _mode = AccessMode.signedOut;
  AuthSession? _session;
  String? _walletAddress;

  AccessMode get mode => _mode;
  AuthSession? get session => _session;
  bool get isGuest => _mode == AccessMode.guest;
  bool get canPurchase => _mode == AccessMode.authenticated;
  String? get walletAddress => _walletAddress;

  void continueAsGuest() {
    _session = null;
    _walletAddress = null;
    _mode = AccessMode.guest;
    notifyListeners();
  }

  Future<void> authenticate(AuthSession session) async {
    final wallet = await walletService.ensureWallet(session.userId);
    _session = session;
    _walletAddress = wallet.address;
    _mode = AccessMode.authenticated;
    notifyListeners();
  }

  void signOut() {
    _session = null;
    _walletAddress = null;
    _mode = AccessMode.signedOut;
    notifyListeners();
  }
}
