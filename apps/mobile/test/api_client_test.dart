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
}
