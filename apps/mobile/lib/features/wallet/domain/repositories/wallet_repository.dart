import 'package:tickerless/features/wallet/domain/entities/wallet_identity.dart';

abstract class WalletRepository {
  /// Returns the account's wallet, deriving and storing a new key the first
  /// time this device sees the account. Idempotent: the same account always
  /// resolves to the same address.
  Future<WalletIdentity> ensureWallet(String userId);

  /// Throws `WalletFailure` when no key exists for the account here.
  Future<String> revealPrivateKey(String userId);
}
