import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tickerless/core/error/exceptions.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/core/network/api_client.dart';
import 'package:tickerless/features/auth/data/datasource/auth_local_datasource.dart';
import 'package:tickerless/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:tickerless/features/auth/data/datasource/google_sign_in_datasource.dart';
import 'package:tickerless/features/auth/data/repositories/auth_repository_impl.dart';

const _sessionBody =
    '{"access_token":"tickerless-session","token_type":"Bearer",'
    '"expires_in":2592000,"user":{"id":"00000000-0000-0000-0000-000000000001",'
    '"email":"owner@example.com","wallet_address":null}}';

void main() {
  late _MemoryTokenStore tokens;

  AuthRepositoryImpl repositoryWith(MockClient client, {String? idToken}) {
    tokens = _MemoryTokenStore();
    return AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(
        client: ApiClient(client: client),
      ),
      localDataSource: tokens,
      googleDataSource: _StubGoogleDataSource(idToken ?? 'signed-google-token'),
    );
  }

  test('Google sign-in exchanges an ID token for a backend session', () async {
    final repository = repositoryWith(
      MockClient((request) async {
        expect(request.url.path, '/v1/auth/google');
        expect(jsonDecode(request.body), {'id_token': 'signed-google-token'});
        return http.Response(_sessionBody, 200);
      }),
    );

    final session = await repository.signInWithGoogle();

    expect(session.accessToken, 'tickerless-session');
    expect(session.email, 'owner@example.com');
    expect(session.userId, '00000000-0000-0000-0000-000000000001');
  });

  test('email sign-in trims the address and caches the session', () async {
    final repository = repositoryWith(
      MockClient((request) async {
        expect(request.url.path, '/v1/auth/email/login');
        expect(jsonDecode(request.body), {
          'email': 'owner@example.com',
          'password': 'secure-password',
        });
        return http.Response(_sessionBody, 200);
      }),
    );

    final session = await repository.signInWithEmail(
      ' owner@example.com ',
      'secure-password',
    );

    expect(session.email, 'owner@example.com');
    expect(tokens.token, 'tickerless-session');
  });

  test('registration surfaces the backend validation message', () async {
    final repository = repositoryWith(
      MockClient((request) async {
        expect(request.url.path, '/v1/auth/email/register');
        return http.Response(
          '{"code":"email_exists","message":"an account already exists for this email"}',
          409,
        );
      }),
    );

    expect(
      () =>
          repository.registerWithEmail('owner@example.com', 'secure-password'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.message,
          'message',
          'an account already exists for this email',
        ),
      ),
    );
  });

  test('a dropped connection reaches the user as plain language', () async {
    final repository = repositoryWith(
      MockClient(
        (request) async => throw http.ClientException(
          'Connection closed before full header was received',
        ),
      ),
    );

    expect(
      () => repository.signInWithEmail('owner@example.com', 'secure-password'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.message,
          'message',
          'No internet connection.',
        ),
      ),
    );
  });

  test('signing out clears the cached token', () async {
    final repository = repositoryWith(
      MockClient((request) async => http.Response(_sessionBody, 200)),
    );
    await repository.signInWithEmail('owner@example.com', 'secure-password');

    await repository.signOut();

    expect(tokens.token, isNull);
  });
}

class _MemoryTokenStore implements AuthLocalDataSource {
  String? token;

  @override
  Future<void> cacheToken(String value) async => token = value;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> clearToken() async => token = null;
}

class _StubGoogleDataSource implements GoogleSignInDataSource {
  const _StubGoogleDataSource(this._idToken);

  final String _idToken;

  @override
  Future<String> obtainIdToken() async {
    if (_idToken.isEmpty) {
      throw const ApiException('Google did not return an identity token');
    }
    return _idToken;
  }
}
