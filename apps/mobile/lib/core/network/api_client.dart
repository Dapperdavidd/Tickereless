import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tickerless/core/constant/api_config.dart';
import 'package:tickerless/core/error/exceptions.dart';

/// The one place that knows the backend speaks JSON over HTTP.
///
/// Feature data sources own their endpoints and their decoding; this owns the
/// transport, the timeout, and turning a non-2xx body into an [ApiException].
class ApiClient {
  ApiClient({http.Client? client, String baseUrl = ApiConfig.baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, Object?> body, {
    required String fallbackError,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.requestTimeout);

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(decoded['message']?.toString() ?? fallbackError);
    }
    return decoded;
  }

  void close() => _client.close();
}
