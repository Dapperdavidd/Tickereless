/// How much of the app the current visitor may use.
///
/// Guests discover freely; owning demo equities needs an account, because a
/// purchase has to land in a wallet that belongs to someone.
enum AccessMode {
  signedOut,
  guest,
  authenticated;

  bool get isGuest => this == AccessMode.guest;
  bool get canPurchase => this == AccessMode.authenticated;
}
