abstract final class ChainConfig {
  static const network = 'Solana Devnet';
  static const rpcUrl = String.fromEnvironment(
    'TICKERLESS_SOLANA_RPC_URL',
    defaultValue: 'https://api.devnet.solana.com',
  );
  static const websocketUrl = String.fromEnvironment(
    'TICKERLESS_SOLANA_WEBSOCKET_URL',
    defaultValue: 'wss://api.devnet.solana.com',
  );
  static const explorerUrl = 'https://explorer.solana.com';

  /// Circle's Solana Devnet USDC mint. It is used for wallet plumbing only;
  /// Tickerless does not issue pretend equity assets.
  static const usdcMint = '4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU';

  /// Populated only after an issuer-backed instrument and executable route
  /// have both been verified for the selected Solana cluster.
  static final executableTickers = <String>{};
}
