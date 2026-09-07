import 'package:tickerless/core/error/exceptions.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/features/wallet/data/datasource/wallet_local_datasource.dart';
import 'package:tickerless/features/wallet/domain/entities/wallet_identity.dart';
import 'package:tickerless/features/wallet/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl({required WalletLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final WalletLocalDataSource _localDataSource;

  @override
  Future<WalletIdentity> ensureWallet(String userId) async {
    try {
      final privateKey = await _localDataSource.ensurePrivateKey(userId);
      return WalletIdentity(address: _localDataSource.addressOf(privateKey));
    } on LocalStorageException catch (error) {
      throw StorageFailure(error.message);
    } catch (error) {
      throw WalletFailure('Could not prepare your wallet: $error');
    }
  }

  @override
  Future<String> revealPrivateKey(String userId) async {
    try {
      return '0x${await _localDataSource.readPrivateKey(userId)}';
    } on MissingWalletException catch (error) {
      throw WalletFailure(error.message);
    } on LocalStorageException catch (error) {
      throw StorageFailure(error.message);
    }
  }
}
