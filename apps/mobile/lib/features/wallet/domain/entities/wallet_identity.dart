import 'package:equatable/equatable.dart';

/// The account's on-chain identity on this device. The private key never
/// leaves the data layer except through `RevealPrivateKeyUseCase`.
class WalletIdentity extends Equatable {
  const WalletIdentity({required this.address});

  final String address;

  /// `0x1234…abcd` — the form every screen shows.
  String get shortAddress =>
      '${address.substring(0, 6)}…${address.substring(address.length - 4)}';

  @override
  List<Object?> get props => [address];
}
