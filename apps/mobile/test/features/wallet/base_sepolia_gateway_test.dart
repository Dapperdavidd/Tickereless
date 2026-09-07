import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tickerless/features/wallet/data/base_sepolia_gateway.dart';
import 'package:tickerless/features/wallet/data/datasource/wallet_local_datasource.dart';

void main() {
  test('decodes USDC and asset balances from contract calls', () async {
    final client = MockClient((request) async {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      final id = payload['id'];
      final params = payload['params'] as List<dynamic>;
      final call = params.first as Map<String, dynamic>;
      final contract = (call['to'] as String).toLowerCase();
      final value = contract == '0x036cbd53842c5426634e7929541ec2318f3dcf7e'
          ? BigInt.from(15 * 1000000)
          : BigInt.zero;
      return http.Response(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': id,
          'result': '0x${value.toRadixString(16).padLeft(64, '0')}',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final snapshot = await BaseSepoliaGateway(
      wallets: _ReadOnlyWallets(),
      httpClient: client,
    ).snapshot('0x10a26dc41ba973ec1a9a37156fd67354992a6ee5');

    expect(snapshot.usdc, 15);
    expect(snapshot.positions, isEmpty);
  });
}

class _ReadOnlyWallets implements WalletLocalDataSource {
  @override
  String addressOf(String privateKey) => throw UnimplementedError();

  @override
  Future<String> ensurePrivateKey(String userId) => throw UnimplementedError();

  @override
  Future<String> readPrivateKey(String userId) => throw UnimplementedError();
}
