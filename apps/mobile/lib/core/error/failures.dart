/// Base failure for the app. Domain and presentation only ever see these.
abstract class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Sign-in, registration, or session exchange did not succeed.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// The resolver could not turn a query, link, or frame into companies.
class ResolverFailure extends Failure {
  const ResolverFailure(super.message);
}

/// Deriving, reading, or storing the account wallet failed.
class WalletFailure extends Failure {
  const WalletFailure(super.message);
}

/// Persisting to the device failed.
class StorageFailure extends Failure {
  const StorageFailure(super.message);
}
