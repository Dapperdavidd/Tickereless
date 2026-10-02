import 'dart:convert';

import 'package:solana/solana.dart';
import 'package:tickerless/core/constant/chain_config.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/wallet/data/chain_gateway.dart';
import 'package:tickerless/features/wallet/data/datasource/wallet_local_datasource.dart';

/// Solana transport used while Tickerless' real-equity execution adapter is
/// being connected. It uses Circle's Devnet USDC mint and never creates or
/// represents demo equity tokens.
class SolanaDevnetGateway implements ChainGateway {
  SolanaDevnetGateway({
    required WalletLocalDataSource wallets,
    SolanaClient? client,
  }) : _wallets = wallets,
       _client =
           client ??
           SolanaClient(
             rpcUrl: Uri.parse(ChainConfig.rpcUrl),
             websocketUrl: Uri.parse(ChainConfig.websocketUrl),
           );

  final WalletLocalDataSource _wallets;
  final SolanaClient _client;

  @override
  Future<OnChainSnapshot> snapshot(String walletAddress) async {
    try {
      final owner = Ed25519HDPublicKey.fromBase58(walletAddress);
      final lamports = (await _client.rpcClient.getBalance(
        walletAddress,
      )).value;
      var usdc = 0.0;
      try {
        final balance = await _client.getTokenBalance(
          owner: owner,
          mint: Ed25519HDPublicKey.fromBase58(ChainConfig.usdcMint),
          commitment: Commitment.confirmed,
        );
        usdc = double.tryParse(balance.uiAmountString ?? '') ?? 0;
      } catch (_) {
        // A new wallet has no USDC associated token account yet.
      }
      return OnChainSnapshot(
        usdc: usdc,
        networkBalance: lamports / lamportsPerSol,
        positions: const [],
      );
    } catch (error) {
      throw WalletFailure('Could not load Solana balances: $error');
    }
  }

  @override
  Future<TransferResult> sendNative({
    required String userId,
    required String recipient,
    required double amount,
  }) async {
    if (amount <= 0) throw const WalletFailure('Enter an amount to send.');
    try {
      final source = await _keyPair(userId);
      final signature = await _client.transferLamports(
        source: source,
        destination: Ed25519HDPublicKey.fromBase58(recipient),
        lamports: (amount * lamportsPerSol).round(),
        commitment: Commitment.confirmed,
      );
      return TransferResult(hash: signature);
    } catch (error) {
      throw WalletFailure('Could not send SOL: $error');
    }
  }

  @override
  Future<TransferResult> sendUsdc({
    required String userId,
    required String recipient,
    required double amount,
  }) async {
    if (amount <= 0) throw const WalletFailure('Enter an amount to send.');
    try {
      final source = await _keyPair(userId);
      final destination = Ed25519HDPublicKey.fromBase58(recipient);
      final mint = Ed25519HDPublicKey.fromBase58(ChainConfig.usdcMint);
      final recipientAccount = await _client.getAssociatedTokenAccount(
        owner: destination,
        mint: mint,
        commitment: Commitment.confirmed,
      );
      if (recipientAccount == null) {
        await _client.createAssociatedTokenAccount(
          owner: destination,
          mint: mint,
          funder: source,
          commitment: Commitment.confirmed,
        );
      }
      final signature = await _client.transferSplToken(
        mint: mint,
        destination: destination,
        amount: (amount * 1000000).round(),
        owner: source,
        commitment: Commitment.confirmed,
      );
      return TransferResult(hash: signature);
    } catch (error) {
      throw WalletFailure('Could not send USDC on Solana: $error');
    }
  }

  @override
  Future<PurchaseResult> buy({
    required String userId,
    required Company company,
    required double usdc,
  }) => throw const WalletFailure(
    'Real tokenized-equity execution is not enabled yet.',
  );

  @override
  Future<SaleResult> sell({
    required String userId,
    required Company company,
    required double tokens,
  }) => throw const WalletFailure(
    'Real tokenized-equity execution is not enabled yet.',
  );

  Future<Ed25519HDKeyPair> _keyPair(String userId) async =>
      Ed25519HDKeyPair.fromPrivateKeyBytes(
        privateKey: base64Decode(await _wallets.readPrivateKey(userId)),
      );
}
