import 'package:equatable/equatable.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';

class PortfolioTransaction extends Equatable {
  const PortfolioTransaction({
    required this.company,
    required this.amount,
    required this.tokens,
    required this.source,
    required this.occurredAt,
  });

  final Company company;
  final double amount;
  final double tokens;
  final String source;
  final DateTime occurredAt;

  @override
  List<Object?> get props => [company, amount, tokens, source, occurredAt];
}
