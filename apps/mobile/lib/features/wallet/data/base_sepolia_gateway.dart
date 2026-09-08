import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:tickerless/core/constant/chain_config.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/features/discovery/data/registry/demo_companies.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';
import 'package:tickerless/features/wallet/data/datasource/wallet_local_datasource.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';

class OnChainSnapshot {
  const OnChainSnapshot({
    required this.usdc,
    required this.eth,
    required this.positions,
  });
  final double usdc;
  final double eth;
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

/// The only mobile boundary that reads balances or signs Base Sepolia calls.
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
  Future<TransferResult> sendEth({
    required String userId,
    required String recipient,
    required double amount,
  });
}

class BaseSepoliaGateway implements ChainGateway {
  BaseSepoliaGateway({
    required WalletLocalDataSource wallets,
    http.Client? httpClient,
  }) : _wallets = wallets,
       _client = Web3Client(ChainConfig.rpcUrl, httpClient ?? http.Client());

  final WalletLocalDataSource _wallets;
  final Web3Client _client;

  static final _erc20Abi = ContractAbi.fromJson(
    '[{"type":"function","name":"balanceOf","stateMutability":"view","inputs":[{"name":"account","type":"address"}],"outputs":[{"name":"balance","type":"uint256"}]},{"type":"function","name":"approve","stateMutability":"nonpayable","inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"approved","type":"bool"}]},{"type":"function","name":"transfer","stateMutability":"nonpayable","inputs":[{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"}],"outputs":[{"name":"sent","type":"bool"}]}]',
    'ERC20',
  );
  static final _marketAbi = ContractAbi.fromJson(
    '[{"type":"function","name":"buy","stateMutability":"nonpayable","inputs":[{"name":"asset","type":"address"},{"name":"amountUsdc","type":"uint256"},{"name":"minimumTokenAmount","type":"uint256"}],"outputs":[{"name":"tokenAmount","type":"uint256"}]},{"type":"function","name":"sell","stateMutability":"nonpayable","inputs":[{"name":"asset","type":"address"},{"name":"tokenAmount","type":"uint256"},{"name":"minimumUsdcAmount","type":"uint256"}],"outputs":[{"name":"amountUsdc","type":"uint256"}]}]',
    'TickerlessMarket',
  );

  @override
  Future<OnChainSnapshot> snapshot(String walletAddress) async {
    try {
      final owner = EthereumAddress.fromHex(walletAddress);
      final balances = await Future.wait([
        _tokenBalance(ChainConfig.usdc, owner),
        for (final address in ChainConfig.assets.values)
          _tokenBalance(address, owner),
      ]);
      final eth = await _client.getBalance(owner);
      final positions = <OwnedPosition>[];
      for (final (index, ticker) in ChainConfig.assets.keys.indexed) {
        final tokens = balances[index + 1] / BigInt.from(10).pow(18);
        if (tokens <= 0) continue;
        final company = _company(ticker);
        positions.add(
          OwnedPosition(
            company: company,
            invested: tokens * ChainConfig.prices[ticker]!,
            tokens: tokens,
            sources: const ['Base Sepolia'],
          ),
        );
      }
      return OnChainSnapshot(
        usdc: balances.first / BigInt.from(10).pow(6),
        eth: eth.getValueInUnit(EtherUnit.ether),
        positions: positions,
      );
    } catch (error) {
      throw WalletFailure('Could not read Base Sepolia balances: $error');
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
      final credentials = EthPrivateKey.fromHex(
        await _wallets.readPrivateKey(userId),
      );
      final contract = DeployedContract(
        _erc20Abi,
        EthereumAddress.fromHex(ChainConfig.usdc),
      );
      final hash = await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: contract.function('transfer'),
          parameters: [
            EthereumAddress.fromHex(recipient),
            BigInt.from((amount * 1000000).round()),
          ],
        ),
        chainId: ChainConfig.chainId,
      );
      await _confirmed(hash);
      return TransferResult(hash: hash);
    } catch (error) {
      if (error is WalletFailure) rethrow;
      throw WalletFailure('USDC transfer failed: $error');
    }
  }

  @override
  Future<TransferResult> sendEth({
    required String userId,
    required String recipient,
    required double amount,
  }) async {
    if (amount <= 0) throw const WalletFailure('Enter an amount to send.');
    try {
      final credentials = EthPrivateKey.fromHex(
        await _wallets.readPrivateKey(userId),
      );
      final wei = BigInt.from((amount * 1e18).round());
      final hash = await _client.sendTransaction(
        credentials,
        Transaction(
          to: EthereumAddress.fromHex(recipient),
          value: EtherAmount.fromBigInt(EtherUnit.wei, wei),
        ),
        chainId: ChainConfig.chainId,
      );
      await _confirmed(hash);
      return TransferResult(hash: hash);
    } catch (error) {
      if (error is WalletFailure) rethrow;
      throw WalletFailure('ETH transfer failed: $error');
    }
  }

  @override
  Future<SaleResult> sell({
    required String userId,
    required Company company,
    required double tokens,
  }) async {
    final assetHex = ChainConfig.assets[company.ticker];
    final price = ChainConfig.prices[company.ticker];
    if (assetHex == null || price == null) {
      throw const WalletFailure(
        'This asset cannot be sold in the test market.',
      );
    }
    if (tokens <= 0) throw const WalletFailure('Enter an amount to sell.');
    try {
      final credentials = EthPrivateKey.fromHex(
        await _wallets.readPrivateKey(userId),
      );
      final tokenAmount = BigInt.from(
        (tokens * BigInt.from(10).pow(18).toDouble()).round(),
      );
      final usdcAmount =
          (tokenAmount * BigInt.from((price * 1000000).round())) ~/
          BigInt.from(10).pow(18);
      final asset = DeployedContract(
        _erc20Abi,
        EthereumAddress.fromHex(assetHex),
      );
      final market = DeployedContract(
        _marketAbi,
        EthereumAddress.fromHex(ChainConfig.market),
      );
      final approval = await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: asset,
          function: asset.function('approve'),
          parameters: [
            EthereumAddress.fromHex(ChainConfig.market),
            tokenAmount,
          ],
        ),
        chainId: ChainConfig.chainId,
      );
      await _confirmed(approval);
      final hash = await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: market,
          function: market.function('sell'),
          parameters: [
            EthereumAddress.fromHex(assetHex),
            tokenAmount,
            usdcAmount,
          ],
        ),
        chainId: ChainConfig.chainId,
      );
      await _confirmed(hash);
      return SaleResult(hash: hash, usdc: usdcAmount / BigInt.from(10).pow(6));
    } catch (error) {
      if (error is WalletFailure) rethrow;
      throw WalletFailure('Base Sepolia sale failed: $error');
    }
  }

  @override
  Future<PurchaseResult> buy({
    required String userId,
    required Company company,
    required double usdc,
  }) async {
    final assetHex = ChainConfig.assets[company.ticker];
    final price = ChainConfig.prices[company.ticker];
    if (assetHex == null || price == null) {
      throw const WalletFailure(
        'This asset is not available in the test market.',
      );
    }
    try {
      final credentials = EthPrivateKey.fromHex(
        await _wallets.readPrivateKey(userId),
      );
      final amount = BigInt.from((usdc * 1000000).round());
      final tokenAmount =
          (amount * BigInt.from(10).pow(18)) ~/
          BigInt.from((price * 1000000).round());
      final usdcContract = DeployedContract(
        _erc20Abi,
        EthereumAddress.fromHex(ChainConfig.usdc),
      );
      final market = DeployedContract(
        _marketAbi,
        EthereumAddress.fromHex(ChainConfig.market),
      );
      final approveHash = await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: usdcContract,
          function: usdcContract.function('approve'),
          parameters: [EthereumAddress.fromHex(ChainConfig.market), amount],
        ),
        chainId: ChainConfig.chainId,
      );
      await _confirmed(approveHash);
      final hash = await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: market,
          function: market.function('buy'),
          parameters: [EthereumAddress.fromHex(assetHex), amount, tokenAmount],
        ),
        chainId: ChainConfig.chainId,
      );
      await _confirmed(hash);
      return PurchaseResult(
        hash: hash,
        tokens: tokenAmount / BigInt.from(10).pow(18),
      );
    } catch (error) {
      if (error is WalletFailure) rethrow;
      throw WalletFailure('Base Sepolia purchase failed: $error');
    }
  }

  Future<BigInt> _tokenBalance(
    String contractAddress,
    EthereumAddress owner,
  ) async {
    final contract = DeployedContract(
      _erc20Abi,
      EthereumAddress.fromHex(contractAddress),
    );
    final result = await _client.call(
      contract: contract,
      function: contract.function('balanceOf'),
      params: [owner],
    );
    return result.single as BigInt;
  }

  Future<void> _confirmed(String hash) async {
    for (var attempt = 0; attempt < 30; attempt++) {
      final receipt = await _client.getTransactionReceipt(hash);
      if (receipt != null) {
        if (receipt.status == false) {
          throw const WalletFailure('The transaction reverted.');
        }
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    throw const WalletFailure(
      'The transaction was submitted but confirmation timed out.',
    );
  }

  static Company _company(String ticker) => switch (ticker) {
    'AAPL' => DemoCompanies.apple,
    'NVDA' => DemoCompanies.nvidia,
    'META' => DemoCompanies.meta,
    'GOOGL' => DemoCompanies.alphabet,
    _ => throw ArgumentError.value(ticker),
  };
}
