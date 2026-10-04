import 'package:tickerless/features/auth/domain/entities/auth_session.dart';
import 'package:tickerless/features/auth/domain/repositories/auth_repository.dart';

class BindWalletUseCase {
  const BindWalletUseCase({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  Future<void> call(AuthSession session, String walletAddress) =>
      _repository.bindWallet(session, walletAddress);
}
