import 'package:flutter_test/flutter_test.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/features/wallet/data/datasource/wallet_local_datasource.dart';
import 'package:tickerless/features/wallet/data/datasource/wallet_secret_store.dart';
import 'package:tickerless/features/wallet/data/repositories/wallet_repository_impl.dart';

void main() {
  WalletRepositoryImpl repositoryWith(WalletSecretStore store) =>
      WalletRepositoryImpl(
        localDataSource: WalletLocalDataSourceImpl(store: store),
      );

  test('creates one stable Ethereum wallet per account', () async {
    final repository = repositoryWith(_MemorySecretStore());

    final first = await repository.ensureWallet('owner-one');
    final second = await repository.ensureWallet('owner-one');
    final other = await repository.ensureWallet('owner-two');

    expect(first.address, matches(RegExp(r'^0x[0-9a-fA-F]{40}$')));
    expect(second.address, first.address);
    expect(other.address, isNot(first.address));
    expect(
      await repository.revealPrivateKey('owner-one'),
      matches(RegExp(r'^0x[0-9a-f]{64}$')),
    );
  });

  test('does not invent a private key during reveal', () async {
    final repository = repositoryWith(_MemorySecretStore());

    expect(
      () => repository.revealPrivateKey('missing'),
      throwsA(isA<WalletFailure>()),
    );
  });

  test('shortens an address for display without losing either end', () async {
    final wallet = await repositoryWith(_MemorySecretStore()).ensureWallet('x');

    expect(wallet.shortAddress, startsWith(wallet.address.substring(0, 6)));
    expect(wallet.shortAddress, endsWith(wallet.address.substring(38)));
  });
}

class _MemorySecretStore implements WalletSecretStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
