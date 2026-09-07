import 'package:equatable/equatable.dart';
import 'package:tickerless/features/portfolio/domain/entities/owned_position.dart';

abstract class PortfolioState extends Equatable {
  const PortfolioState();

  @override
  List<Object?> get props => [];
}

class PortfolioInitial extends PortfolioState {
  const PortfolioInitial();
}

class PortfolioLoaded extends PortfolioState {
  const PortfolioLoaded(this.positions);

  final List<OwnedPosition> positions;

  double get total =>
      positions.fold(0, (sum, position) => sum + position.invested);

  int get discoveryCount =>
      positions.fold(0, (sum, position) => sum + position.sources.length);

  @override
  List<Object?> get props => [positions];
}

class PortfolioError extends PortfolioState {
  const PortfolioError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
