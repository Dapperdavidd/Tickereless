import 'package:tickerless/features/auth/domain/entities/auth_session.dart';
import 'package:tickerless/features/auth/domain/repositories/auth_repository.dart';

class RestoreSessionUseCase {
  const RestoreSessionUseCase({required AuthRepository repository})
    : _repository = repository;
  final AuthRepository _repository;
  Future<AuthSession?> call() => _repository.restoreSession();
}
