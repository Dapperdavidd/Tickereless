import 'package:equatable/equatable.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';

abstract class PortfolioEvent extends Equatable {
  const PortfolioEvent();

  @override
  List<Object?> get props => [];
}

class PortfolioRequested extends PortfolioEvent {
  const PortfolioRequested();
}

class PurchaseRecorded extends PortfolioEvent {
  const PurchaseRecorded({
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
