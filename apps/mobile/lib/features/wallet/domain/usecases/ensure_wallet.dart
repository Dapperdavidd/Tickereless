import 'package:tickerless/features/wallet/domain/entities/wallet_identity.dart';
import 'package:tickerless/features/wallet/domain/repositories/wallet_repository.dart';

class EnsureWalletUseCase {
  const EnsureWalletUseCase({required WalletRepository repository})
    : _repository = repository;

  final WalletRepository _repository;

  Future<WalletIdentity> call(String userId) =>
      _repository.ensureWallet(userId);
}
