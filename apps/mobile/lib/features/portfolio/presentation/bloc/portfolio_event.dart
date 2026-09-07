import 'package:equatable/equatable.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';
import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';

abstract class PortfolioEvent extends Equatable {
  const PortfolioEvent();

  @override
  List<Object?> get props => [];
}

class PortfolioRequested extends PortfolioEvent {
  const PortfolioRequested();
}

class PortfolioChainSynced extends PortfolioEvent {
  const PortfolioChainSynced(this.positions);
  final List<OwnedPosition> positions;

  @override
  List<Object?> get props => [positions];
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
