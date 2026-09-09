import 'dart:async';
import 'dart:io';

import 'package:tickerless/core/error/failures.dart';

enum WalletOperation { load, purchase, sale, usdcTransfer, ethTransfer }

/// Converts provider, JSON-RPC, and transport errors into stable user copy.
/// Raw node messages are useful in logs, but never belong in the interface.
WalletFailure presentableWalletFailure(
  Object error, {
  required WalletOperation operation,
}) {
  if (error is WalletFailure) return error;

  final text = error.toString().toLowerCase();
  if (error is SocketException ||
      text.contains('failed host lookup') ||
      text.contains('socketexception') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('connection closed')) {
    return const WalletFailure(
      'You appear to be offline. Check your connection and try again.',
      kind: WalletFailureKind.network,
    );
  }
  if (error is TimeoutException ||
      text.contains('timeout') ||
      text.contains('timed out')) {
    return const WalletFailure(
      'The Base Sepolia network is taking too long. Try again shortly.',
      kind: WalletFailureKind.network,
    );
  }
  if (text.contains('gas required exceeds allowance') ||
      text.contains('insufficient funds for gas') ||
      text.contains('insufficient funds for intrinsic transaction cost') ||
      text.contains('sender balance is insufficient')) {
    return const WalletFailure(
      'You need Base Sepolia ETH to pay the network fee. Add test ETH to your wallet and try again.',
      kind: WalletFailureKind.needsNetworkFee,
    );
  }
  if (text.contains('nonce too low') ||
      text.contains('replacement transaction underpriced') ||
      text.contains('already known')) {
    return const WalletFailure(
      'Another wallet transaction is still pending. Wait for it to finish, then try again.',
    );
  }
  if (text.contains('rate limit') ||
      text.contains('too many requests') ||
      text.contains('code -32005')) {
    return const WalletFailure(
      'The Base Sepolia network is busy. Try again in a moment.',
      kind: WalletFailureKind.network,
    );
  }
  if (text.contains('insufficient balance') ||
      text.contains('transfer amount exceeds balance')) {
    return WalletFailure(
      _balanceMessage(operation),
      kind: WalletFailureKind.insufficientBalance,
    );
  }
  if (text.contains('execution reverted') || text.contains('revert')) {
    return const WalletFailure(
      'The network rejected this transaction. Check your balances and try again.',
    );
  }

  return WalletFailure(_fallbackMessage(operation));
}

String _balanceMessage(WalletOperation operation) => switch (operation) {
  WalletOperation.purchase || WalletOperation.usdcTransfer =>
    'Your USDC balance is too low for this transaction.',
  WalletOperation.sale => 'Your asset balance is too low for this sale.',
  WalletOperation.ethTransfer =>
    'Your Base Sepolia ETH balance is too low for the amount and network fee.',
  WalletOperation.load => 'Your wallet balance could not be loaded.',
};

String _fallbackMessage(WalletOperation operation) => switch (operation) {
  WalletOperation.load =>
    'Your Base Sepolia balances are unavailable right now. Pull to refresh.',
  WalletOperation.purchase =>
    'We couldn’t complete this purchase. Try again in a moment.',
  WalletOperation.sale => 'We couldn’t complete this sale. Try again shortly.',
  WalletOperation.usdcTransfer || WalletOperation.ethTransfer =>
    'We couldn’t send this transaction. Try again shortly.',
};
