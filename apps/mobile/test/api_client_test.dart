import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tickerless/src/services/api_client.dart';

void main() {
  test('search maps backend company and Base asset contract', () async {
    final api = TickerlessApi(
      client: MockClient((request) async {
        expect(request.url.path, '/v1/resolve/search');
        return http.Response(
          '{"matches":[{"company":{"slug":"meta","name":"Meta Platforms","ticker":"META","description":"Behind Instagram","aliases":["Instagram","WhatsApp"],"asset":{"symbol":"tMETAc","price_usdc":"500.000000"}},"reason":"Instagram is associated with Meta Platforms.","confidence":0.95}]}',
          200,
        );
      }),
    );

    final matches = await api.search('company behind Instagram');
    expect(matches.single.company.name, 'Meta Platforms');
    expect(matches.single.company.symbol, 'tMETAc');
    expect(matches.single.company.price, 500);
    expect(matches.single.confidence, .95);
  });

  test('lens sends OCR text and visual labels to the resolver', () async {
    final api = TickerlessApi(
      client: MockClient((request) async {
        expect(request.url.path, '/v1/resolve/image');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['text'], 'GEFORCE RTX');
        expect(body['labels'], ['graphics card', 'computer hardware']);
        return http.Response('{"matches":[]}', 200);
      }),
    );

    final matches = await api.lens(
      'GEFORCE RTX',
      labels: ['graphics card', 'computer hardware'],
    );
    expect(matches, isEmpty);
  });

  test('Google login exchanges an ID token for a backend session', () async {
    final api = TickerlessApi(
      client: MockClient((request) async {
        expect(request.url.path, '/v1/auth/google');
        expect(jsonDecode(request.body), {'id_token': 'signed-google-token'});
        return http.Response(
          '{"access_token":"tickerless-session","token_type":"Bearer","expires_in":2592000,"user":{"id":"00000000-0000-0000-0000-000000000001","email":"owner@example.com","wallet_address":null}}',
          200,
        );
      }),
    );

    final session = await api.googleLogin('signed-google-token');
    expect(session.accessToken, 'tickerless-session');
    expect(session.email, 'owner@example.com');
  });
}
