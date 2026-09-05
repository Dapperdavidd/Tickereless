import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/company.dart';

class TickerlessApi {
  TickerlessApi({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = String.fromEnvironment(
    'TICKERLESS_API_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );

  final http.Client _client;

  Future<List<CompanyMatch>> search(String query) =>
      _resolve('/v1/resolve/search', {'query': query});

  Future<List<CompanyMatch>> link(String url) =>
      _resolve('/v1/resolve/link', {'url': url});

  Future<List<CompanyMatch>> lens(
    String text, {
    List<String> labels = const [],
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/v1/resolve/image'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'text': text, 'labels': labels}),
        )
        .timeout(const Duration(seconds: 12));
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded['message']?.toString() ?? 'Recognition failed',
      );
    }
    return (decoded['matches'] as List<dynamic>? ?? const [])
        .map((value) => CompanyMatch.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  Future<List<CompanyMatch>> _resolve(
    String path,
    Map<String, String> body,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(decoded['message']?.toString() ?? 'Request failed');
    }
    final matches = decoded['matches'] as List<dynamic>? ?? const [];
    return matches
        .map((value) => CompanyMatch.fromJson(value as Map<String, dynamic>))
        .toList();
  }
}

class CompanyMatch {
  const CompanyMatch({
    required this.company,
    required this.reason,
    required this.confidence,
  });

  factory CompanyMatch.fromJson(Map<String, dynamic> json) {
    final company = json['company'] as Map<String, dynamic>;
    final asset = (json['asset'] ?? company['asset']) as Map<String, dynamic>?;
    final slug = company['slug']?.toString() ?? '';
    return CompanyMatch(
      company: Company(
        name: company['name'].toString(),
        ticker: company['ticker'].toString(),
        symbol: asset?['symbol']?.toString() ?? company['ticker'].toString(),
        description: company['description']?.toString() ?? '',
        products: (company['aliases'] as List<dynamic>? ?? const [])
            .take(3)
            .map((e) => e.toString())
            .toList(),
        color: switch (slug) {
          'nvidia' => const Color(0xFF9BFF00),
          'meta' => const Color(0xFF38A5FF),
          _ => Colors.white,
        },
        price: double.tryParse(asset?['price_usdc']?.toString() ?? '') ?? 0,
        change: 0,
      ),
      reason:
          json['reason']?.toString() ?? 'Matched by the Tickerless resolver',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  final Company company;
  final String reason;
  final double confidence;
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
