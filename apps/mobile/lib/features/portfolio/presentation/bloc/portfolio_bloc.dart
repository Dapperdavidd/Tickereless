import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/features/portfolio/domain/usecases/get_positions.dart';
import 'package:tickerless/features/portfolio/domain/usecases/record_purchase.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_event.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_state.dart';

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  PortfolioBloc({
    required GetPositionsUseCase getPositions,
    required RecordPurchaseUseCase recordPurchase,
  }) : _getPositions = getPositions,
       _recordPurchase = recordPurchase,
       super(const PortfolioInitial()) {
    on<PortfolioRequested>(_onRequested);
    on<PurchaseRecorded>(_onPurchaseRecorded);
  }

  final GetPositionsUseCase _getPositions;
  final RecordPurchaseUseCase _recordPurchase;

  Future<void> _onRequested(
    PortfolioRequested event,
    Emitter<PortfolioState> emit,
  ) async {
    try {
      emit(PortfolioLoaded(await _getPositions()));
    } on Failure catch (failure) {
      emit(PortfolioError(failure.message));
    }
  }

  Future<void> _onPurchaseRecorded(
    PurchaseRecorded event,
    Emitter<PortfolioState> emit,
  ) async {
    try {
      emit(
        PortfolioLoaded(
          await _recordPurchase(
            company: event.company,
            invested: event.invested,
            tokens: event.tokens,
            source: event.source,
          ),
        ),
      );
    } on Failure catch (failure) {
      emit(PortfolioError(failure.message));
    }
  }
}
