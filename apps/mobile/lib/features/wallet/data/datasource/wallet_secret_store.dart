import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tickerless/core/error/exceptions.dart';

/// The narrow slice of secure storage the wallet needs — narrow enough that
/// tests substitute an in-memory map without touching the Keychain.
abstract interface class WalletSecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class KeychainWalletSecretStore implements WalletSecretStore {
  KeychainWalletSecretStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (error) {
      throw LocalStorageException('Could not read the wallet key: $error');
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error) {
      throw LocalStorageException('Could not store the wallet key: $error');
    }
  }
}
