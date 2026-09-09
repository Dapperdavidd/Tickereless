import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/features/discovery/data/registry/demo_companies.dart';
import 'package:tickerless/features/wallet/data/base_sepolia_gateway.dart';
import 'package:tickerless/features/wallet/data/datasource/wallet_local_datasource.dart';
import 'package:tickerless/features/wallet/data/wallet_failure_mapper.dart';

void main() {
  test('decodes USDC and asset balances from contract calls', () async {
    final client = MockClient((request) async {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      final id = payload['id'];
      if (payload['method'] == 'eth_getBalance') {
        return http.Response(
          jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': '0x0'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      final params = payload['params'] as List<dynamic>;
      final call = params.first as Map<String, dynamic>;
      final contract = (call['to'] as String).toLowerCase();
      final value = switch (contract) {
        '0x036cbd53842c5426634e7929541ec2318f3dcf7e' => BigInt.from(
          15 * 1000000,
        ),
        '0xecb227cccce78c2452188e656cde26225fcbcd39' => BigInt.from(10).pow(18),
        '0xf1c8912f560b89779f00a59bcb5a43b5001f8fb2' =>
          BigInt.two * BigInt.from(10).pow(18),
        '0x1a8babbe375b00d82281b4a5323b7587df0ceee6' =>
          BigInt.from(3) * BigInt.from(10).pow(18),
        '0xba66850b6bb6ad7460db33ef057f0ce6c022df89' =>
          BigInt.from(4) * BigInt.from(10).pow(18),
        _ => BigInt.zero,
      };
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
    expect(snapshot.eth, 0);
    expect(snapshot.positions.map((position) => position.company.ticker), [
      'AAPL',
      'NVDA',
      'META',
      'GOOGL',
    ]);
    expect(snapshot.positions.map((position) => position.invested), [
      200,
      360,
      1500,
      600,
    ]);
  });

  test('maps raw RPC gas errors to an actionable user message', () {
    final failure = presentableWalletFailure(
      Exception(
        'RPCError: got code -32000 with msg "gas required exceeds allowance (0)"',
      ),
      operation: WalletOperation.purchase,
    );

    expect(failure.kind, WalletFailureKind.needsNetworkFee);
    expect(
      failure.message,
      'You need Base Sepolia ETH to pay the network fee. Add test ETH to your wallet and try again.',
    );
    expect(failure.message, isNot(contains('RPCError')));
    expect(failure.message, isNot(contains('-32000')));
  });

  test('purchase stops before signing when the wallet has no gas', () async {
    final client = MockClient((request) async {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({'jsonrpc': '2.0', 'id': payload['id'], 'result': '0x0'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final gateway = BaseSepoliaGateway(
      wallets: _WalletsWithKey(),
      httpClient: client,
    );

    await expectLater(
      gateway.buy(userId: 'owner', company: DemoCompanies.meta, usdc: 5),
      throwsA(
        isA<WalletFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              WalletFailureKind.needsNetworkFee,
            )
            .having(
              (failure) => failure.message,
              'message',
              contains('Add test ETH'),
            ),
      ),
    );
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

class _WalletsWithKey extends _ReadOnlyWallets {
  @override
  Future<String> readPrivateKey(String userId) async => '1'.padLeft(64, '0');
}
