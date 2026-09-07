import 'package:flutter_test/flutter_test.dart';
import 'package:tickerless/src/services/wallet_service.dart';

void main() {
  test('creates one stable Ethereum wallet per account', () async {
    final store = _MemorySecretStore();
    final service = WalletService(store: store);

    final first = await service.ensureWallet('owner-one');
    final second = await service.ensureWallet('owner-one');
    final other = await service.ensureWallet('owner-two');

    expect(first.address, matches(RegExp(r'^0x[0-9a-fA-F]{40}$')));
    expect(second.address, first.address);
    expect(other.address, isNot(first.address));
    expect(
      await service.revealPrivateKey('owner-one'),
      matches(RegExp(r'^0x[0-9a-f]{64}$')),
    );
  });

  test('does not invent a private key during reveal', () async {
    final service = WalletService(store: _MemorySecretStore());
    expect(
      () => service.revealPrivateKey('missing'),
      throwsA(isA<StateError>()),
    );
  });
}

class _MemorySecretStore implements WalletSecretStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
