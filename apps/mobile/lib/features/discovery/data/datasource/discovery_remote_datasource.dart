import 'package:tickerless/core/network/api_client.dart';
import 'package:tickerless/features/discovery/data/model/company_match_model.dart';

/// The resolver's three entry points: a phrase, a URL, a camera frame.
abstract interface class DiscoveryRemoteDataSource {
  Future<List<CompanyMatchModel>> search(String query);
  Future<List<CompanyMatchModel>> resolveLink(String url);
  Future<List<CompanyMatchModel>> recognize(String text, List<String> labels);
}

class DiscoveryRemoteDataSourceImpl implements DiscoveryRemoteDataSource {
  DiscoveryRemoteDataSourceImpl({ApiClient? client})
    : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<List<CompanyMatchModel>> search(String query) => _matches(
    '/v1/resolve/search',
    {'query': query},
    fallbackError: 'Search failed',
  );

  @override
  Future<List<CompanyMatchModel>> resolveLink(String url) => _matches(
    '/v1/resolve/link',
    {'url': url},
    fallbackError: 'Link analysis failed',
  );

  @override
  Future<List<CompanyMatchModel>> recognize(String text, List<String> labels) =>
      _matches('/v1/resolve/image', {
        'text': text,
        'labels': labels,
      }, fallbackError: 'Recognition failed');

  Future<List<CompanyMatchModel>> _matches(
    String path,
    Map<String, Object?> body, {
    required String fallbackError,
  }) async {
    final decoded = await _client.postJson(
      path,
      body,
      fallbackError: fallbackError,
    );
    return (decoded['matches'] as List<dynamic>? ?? const [])
        .map(
          (match) => CompanyMatchModel.fromJson(match as Map<String, dynamic>),
        )
        .toList();
  }
}
