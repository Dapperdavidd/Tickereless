import 'package:tickerless/features/auth/domain/entities/auth_session.dart';
import 'package:tickerless/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  const SignInWithEmailUseCase({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  Future<AuthSession> call(String email, String password) =>
      _repository.signInWithEmail(email, password);
}
