import 'package:tickerless/features/wallet/domain/repositories/wallet_repository.dart';

class RevealPrivateKeyUseCase {
  const RevealPrivateKeyUseCase({required WalletRepository repository})
    : _repository = repository;

  final WalletRepository _repository;

  Future<String> call(String userId) => _repository.revealPrivateKey(userId);
}
