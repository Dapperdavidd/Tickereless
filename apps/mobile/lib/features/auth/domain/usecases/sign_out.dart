import 'package:tickerless/features/auth/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  const SignOutUseCase({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}
