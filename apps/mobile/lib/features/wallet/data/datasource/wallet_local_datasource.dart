import 'dart:convert';

import 'package:solana/solana.dart';
import 'package:tickerless/core/error/exceptions.dart';
import 'package:tickerless/features/wallet/data/datasource/wallet_secret_store.dart';

/// Owns key generation and derivation. The only code in the app that handles
/// raw private key material.
abstract interface class WalletLocalDataSource {
  Future<String> ensurePrivateKey(String userId);
  Future<String> readPrivateKey(String userId);
  Future<String> addressOf(String privateKey);
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

    final credentials = await Ed25519HDKeyPair.random();
    final privateKey = base64Encode((await credentials.extract()).bytes);
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
  Future<String> addressOf(String privateKey) async =>
      (await keyPairOf(privateKey)).address;

  Future<Ed25519HDKeyPair> keyPairOf(String privateKey) =>
      Ed25519HDKeyPair.fromPrivateKeyBytes(
        privateKey: base64Decode(privateKey),
      );

  String _keyName(String userId) => 'tickerless_solana_wallet_$userId';
}
