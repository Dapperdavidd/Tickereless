import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tickerless/core/error/exceptions.dart';

/// Where the session token lives between launches.
abstract interface class AuthLocalDataSource {
  Future<void> cacheToken(String token);
  Future<String?> readToken();
  Future<void> clearToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'tickerless_session_token';

  final FlutterSecureStorage _storage;

  @override
  Future<void> cacheToken(String token) async {
    try {
      await _storage.write(key: _sessionKey, value: token);
    } catch (error) {
      throw LocalStorageException('Could not store the session: $error');
    }
  }

  @override
  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _sessionKey);
    } catch (error) {
      throw LocalStorageException('Could not read the session: $error');
    }
  }

  @override
  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _sessionKey);
    } catch (error) {
      throw LocalStorageException('Could not clear the session: $error');
    }
  }
}
