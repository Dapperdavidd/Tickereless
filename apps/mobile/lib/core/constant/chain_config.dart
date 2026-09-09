abstract final class ChainConfig {
  static const chainId = 84532;
  static const rpcUrl = 'https://sepolia.base.org';
  static const explorerUrl = 'https://sepolia.basescan.org';
  static const usdc = '0x036cbd53842c5426634e7929541ec2318f3dcf7e';
  static const market = '0xd747a01cd827ff9ad69d5d8eaaf774aaf2695c9a';
  static const microsoft = String.fromEnvironment(
    'TICKERLESS_MSFT_TOKEN_ADDRESS',
  );

  static final assets = <String, String>{
    'AAPL': '0xecb227cccce78c2452188e656cde26225fcbcd39',
    'NVDA': '0xf1c8912f560b89779f00a59bcb5a43b5001f8fb2',
    'META': '0x1a8babbe375b00d82281b4a5323b7587df0ceee6',
    'GOOGL': '0xba66850b6bb6ad7460db33ef057f0ce6c022df89',
    if (microsoft.isNotEmpty) 'MSFT': microsoft,
  };

  static const prices = {
    'AAPL': 200.0,
    'NVDA': 180.0,
    'META': 500.0,
    'GOOGL': 150.0,
    'MSFT': 430.2,
  };
}
