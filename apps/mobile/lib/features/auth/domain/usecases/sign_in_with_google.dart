import 'package:tickerless/features/auth/domain/entities/auth_session.dart';
import 'package:tickerless/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  Future<AuthSession> call() => _repository.signInWithGoogle();
}
