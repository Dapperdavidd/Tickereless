import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';

WalletService walletService = WalletService();

abstract interface class WalletSecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class KeychainWalletSecretStore implements WalletSecretStore {
  KeychainWalletSecretStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class WalletIdentity {
  const WalletIdentity({required this.address});
  final String address;
}

class WalletService {
  WalletService({WalletSecretStore? store})
    : _store = store ?? KeychainWalletSecretStore();

  final WalletSecretStore _store;

  Future<WalletIdentity> ensureWallet(String userId) async {
    final keyName = _keyName(userId);
    var privateKey = await _store.read(keyName);
    if (privateKey == null) {
      final credentials = EthPrivateKey.createRandom(Random.secure());
      privateKey = credentials.privateKeyInt.toRadixString(16).padLeft(64, '0');
      await _store.write(keyName, privateKey);
    }
    final credentials = EthPrivateKey.fromHex(privateKey);
    return WalletIdentity(address: credentials.address.with0x);
  }

  Future<String> revealPrivateKey(String userId) async {
    final privateKey = await _store.read(_keyName(userId));
    if (privateKey == null) {
      throw StateError('No wallet exists for this account on this device.');
    }
    return '0x$privateKey';
  }

  String _keyName(String userId) => 'tickerless_wallet_$userId';
}
