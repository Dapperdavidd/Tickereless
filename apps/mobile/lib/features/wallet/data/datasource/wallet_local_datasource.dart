import 'dart:math';

import 'package:tickerless/core/error/exceptions.dart';
import 'package:tickerless/features/wallet/data/datasource/wallet_secret_store.dart';
import 'package:web3dart/web3dart.dart';

/// Owns key generation and derivation. The only code in the app that handles
/// raw private key material.
abstract interface class WalletLocalDataSource {
  Future<String> ensurePrivateKey(String userId);
  Future<String> readPrivateKey(String userId);
  String addressOf(String privateKey);
}

class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  WalletLocalDataSourceImpl({WalletSecretStore? store})
    : _store = store ?? KeychainWalletSecretStore();

  final WalletSecretStore _store;

  @override
  Future<String> ensurePrivateKey(String userId) async {
    final keyName = _keyName(userId);
    final existing = await _store.read(keyName);
    if (existing != null) return existing;

    final credentials = EthPrivateKey.createRandom(Random.secure());
    final privateKey = credentials.privateKeyInt
        .toRadixString(16)
        .padLeft(64, '0');
    await _store.write(keyName, privateKey);
    return privateKey;
  }

  @override
  Future<String> readPrivateKey(String userId) async {
    final privateKey = await _store.read(_keyName(userId));
    if (privateKey == null) {
      throw const MissingWalletException(
        'No wallet exists for this account on this device.',
      );
    }
    return privateKey;
  }

  @override
  String addressOf(String privateKey) =>
      EthPrivateKey.fromHex(privateKey).address.with0x;

  String _keyName(String userId) => 'tickerless_wallet_$userId';
}
