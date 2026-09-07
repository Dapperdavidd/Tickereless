import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tickerless/core/error/exceptions.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/core/network/api_client.dart';
import 'package:tickerless/features/discovery/data/datasource/discovery_remote_datasource.dart';
import 'package:tickerless/features/discovery/data/datasource/frame_analysis_datasource.dart';
import 'package:tickerless/features/discovery/data/repositories/discovery_repository_impl.dart';

void main() {
  DiscoveryRepositoryImpl repositoryWith(
    MockClient client, {
    FrameAnalysis? frame,
  }) => DiscoveryRepositoryImpl(
    remoteDataSource: DiscoveryRemoteDataSourceImpl(
      client: ApiClient(client: client),
    ),
    frameDataSource: _StubFrameDataSource(
      frame ?? const FrameAnalysis(text: '', labels: []),
    ),
  );

  test('search maps the backend company and its Base asset', () async {
    final repository = repositoryWith(
      MockClient((request) async {
        expect(request.url.path, '/v1/resolve/search');
        return http.Response(
          '{"matches":[{"company":{"slug":"meta","name":"Meta Platforms",'
          '"ticker":"META","description":"Behind Instagram",'
          '"aliases":["Instagram","WhatsApp"],'
          '"asset":{"symbol":"tMETAc","price_usdc":"500.000000"}},'
          '"reason":"Instagram is associated with Meta Platforms.",'
          '"confidence":0.95}]}',
          200,
        );
      }),
    );

    final matches = await repository.search('company behind Instagram');

    expect(matches.single.company.name, 'Meta Platforms');
    expect(matches.single.company.symbol, 'tMETAc');
    expect(matches.single.company.price, 500);
    expect(matches.single.company.products, ['Instagram', 'WhatsApp']);
    expect(matches.single.confidence, .95);
  });

  test('a captured frame sends its text and labels to the resolver', () async {
    final repository = repositoryWith(
      MockClient((request) async {
        expect(request.url.path, '/v1/resolve/image');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['text'], 'GEFORCE RTX');
        expect(body['labels'], ['graphics card', 'computer hardware']);
        return http.Response('{"matches":[]}', 200);
      }),
      frame: const FrameAnalysis(
        text: 'GEFORCE RTX',
        labels: ['graphics card', 'computer hardware'],
      ),
    );

    expect(await repository.recognizeFrame('/tmp/frame.jpg'), isEmpty);
  });

  test('an illegible frame never reaches the resolver', () async {
    final repository = repositoryWith(
      MockClient((request) async => fail('the resolver should not be called')),
    );

    expect(await repository.recognizeFrame('/tmp/blank.jpg'), isEmpty);
  });

  test('a vision failure becomes a resolver failure, not a crash', () async {
    final repository = DiscoveryRepositoryImpl(
      remoteDataSource: DiscoveryRemoteDataSourceImpl(
        client: ApiClient(
          client: MockClient((request) async => http.Response('{}', 200)),
        ),
      ),
      frameDataSource: const _ThrowingFrameDataSource(),
    );

    expect(
      () => repository.recognizeFrame('/tmp/frame.jpg'),
      throwsA(
        isA<ResolverFailure>().having(
          (failure) => failure.message,
          'message',
          'Vision is unavailable',
        ),
      ),
    );
  });

  test('a resolver error message is passed through verbatim', () async {
    final repository = repositoryWith(
      MockClient(
        (request) async =>
            http.Response('{"message":"unsupported link host"}', 422),
      ),
    );

    expect(
      () => repository.resolveLink('https://example.com'),
      throwsA(
        isA<ResolverFailure>().having(
          (failure) => failure.message,
          'message',
          'unsupported link host',
        ),
      ),
    );
  });
}

class _StubFrameDataSource implements FrameAnalysisDataSource {
  const _StubFrameDataSource(this._analysis);

  final FrameAnalysis _analysis;

  @override
  Future<FrameAnalysis> analyze(String imagePath) async => _analysis;
}

class _ThrowingFrameDataSource implements FrameAnalysisDataSource {
  const _ThrowingFrameDataSource();

  @override
  Future<FrameAnalysis> analyze(String imagePath) async =>
      throw const ImageAnalysisException('Vision is unavailable');
}
