import 'package:tickerless/features/auth/domain/entities/auth_session.dart';
import 'package:tickerless/features/auth/domain/repositories/auth_repository.dart';

class RegisterWithEmailUseCase {
  const RegisterWithEmailUseCase({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  Future<AuthSession> call(String email, String password) =>
      _repository.registerWithEmail(email, password);
}
