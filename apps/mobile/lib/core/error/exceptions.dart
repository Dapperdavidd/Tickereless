/// Exceptions are what the data layer throws. Repositories catch them and
/// rethrow the matching `Failure`, so nothing above the data layer has to know
/// that an HTTP call or a Keychain read was involved.
library;

/// The backend answered, but with an error status.
class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Reading or writing the platform secure store failed.
class LocalStorageException implements Exception {
  const LocalStorageException(this.message);
  final String message;

  @override
  String toString() => 'LocalStorageException: $message';
}

/// No wallet key exists for the account on this device.
class MissingWalletException implements Exception {
  const MissingWalletException(this.message);
  final String message;

  @override
  String toString() => 'MissingWalletException: $message';
}

/// The platform vision channel could not analyse the frame.
class ImageAnalysisException implements Exception {
  const ImageAnalysisException(this.message);
  final String message;

  @override
  String toString() => 'ImageAnalysisException: $message';
}
