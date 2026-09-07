import 'package:equatable/equatable.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';

/// Arguments passed through `GoRouter`'s `extra`.
///
/// The discovery flows carry a company object the resolver already returned,
/// so re-fetching it by ticker on every hop would be a round trip for data the
/// caller is holding.

class PassportArgs extends Equatable {
  const PassportArgs({required this.company, required this.source});

  final Company company;

  /// Provenance, e.g. `iPhone · Lens` — carried all the way to the receipt.
  final String source;

  @override
  List<Object?> get props => [company, source];
}

class PurchaseArgs extends Equatable {
  const PurchaseArgs({required this.company, required this.source});

  final Company company;
  final String source;

  @override
  List<Object?> get props => [company, source];
}

class ReceiptArgs extends Equatable {
  const ReceiptArgs({
    required this.company,
    required this.invested,
    required this.tokens,
    required this.source,
  });

  final Company company;
  final double invested;
  final double tokens;
  final String source;

  @override
  List<Object?> get props => [company, invested, tokens, source];
}
