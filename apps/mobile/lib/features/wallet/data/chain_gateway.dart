import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';

class OnChainSnapshot {
  const OnChainSnapshot({
    required this.usdc,
    required this.networkBalance,
    required this.positions,
  });

  final double usdc;
  final double networkBalance;
  final List<OwnedPosition> positions;
}

class PurchaseResult {
  const PurchaseResult({required this.hash, required this.tokens});
  final String hash;
  final double tokens;
}

class SaleResult {
  const SaleResult({required this.hash, required this.usdc});
  final String hash;
  final double usdc;
}

class TransferResult {
  const TransferResult({required this.hash});
  final String hash;
}

/// Chain-neutral boundary for balances, settlement, and transfers.
abstract interface class ChainGateway {
  Future<OnChainSnapshot> snapshot(String walletAddress);
  Future<PurchaseResult> buy({
    required String userId,
    required Company company,
    required double usdc,
  });
  Future<SaleResult> sell({
    required String userId,
    required Company company,
    required double tokens,
  });
  Future<TransferResult> sendUsdc({
    required String userId,
    required String recipient,
    required double amount,
  });
  Future<TransferResult> sendNative({
    required String userId,
    required String recipient,
    required double amount,
  });
}
