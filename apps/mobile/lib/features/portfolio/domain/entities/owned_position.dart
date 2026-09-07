import 'package:equatable/equatable.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';

/// What the user owns of one company, and what led them to it.
class OwnedPosition extends Equatable {
  const OwnedPosition({
    required this.company,
    required this.invested,
    required this.tokens,
    required this.sources,
  });

  final Company company;

  /// USDC put in, across every purchase of this company.
  final double invested;
  final double tokens;

  /// Distinct provenance lines, e.g. `iPhone · Lens`.
  final List<String> sources;

  /// Folds another purchase into this position, keeping provenance unique.
  OwnedPosition merge({
    required double invested,
    required double tokens,
    required String source,
  }) => OwnedPosition(
    company: company,
    invested: this.invested + invested,
    tokens: this.tokens + tokens,
    sources: {...sources, source}.toList(),
  );

  @override
  List<Object?> get props => [company, invested, tokens, sources];
}
