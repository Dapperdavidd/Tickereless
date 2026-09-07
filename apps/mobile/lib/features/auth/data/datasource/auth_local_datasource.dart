import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tickerless/core/error/exceptions.dart';
import 'package:tickerless/features/auth/domain/entities/auth_session.dart';

/// Where the session token lives between launches.
abstract interface class AuthLocalDataSource {
  Future<void> cacheToken(String token);
  Future<void> cacheSession(AuthSession session);
  Future<String?> readToken();
  Future<AuthSession?> readSession();
  Future<void> clearToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'tickerless_session_token';
  static const _identityKey = 'tickerless_session_identity';

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
  Future<void> cacheSession(AuthSession session) async {
    try {
      await _storage.write(key: _sessionKey, value: session.accessToken);
      await _storage.write(
        key: _identityKey,
        value: jsonEncode({
          'access_token': session.accessToken,
          'email': session.email,
          'user_id': session.userId,
        }),
      );
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
  Future<AuthSession?> readSession() async {
    try {
      final encoded = await _storage.read(key: _identityKey);
      if (encoded == null) return null;
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      return AuthSession(
        accessToken: json['access_token'].toString(),
        email: json['email'].toString(),
        userId: json['user_id'].toString(),
      );
    } catch (error) {
      throw LocalStorageException('Could not read the session: $error');
    }
  }

  @override
  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _sessionKey);
      await _storage.delete(key: _identityKey);
    } catch (error) {
      throw LocalStorageException('Could not clear the session: $error');
    }
  }
}
