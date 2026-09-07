import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/features/portfolio/domain/usecases/get_positions.dart';
import 'package:tickerless/features/portfolio/domain/usecases/record_purchase.dart';
import 'package:tickerless/features/portfolio/domain/entities/portfolio_transaction.dart';
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
    on<PortfolioChainSynced>(_onChainSynced);
    on<PurchaseRecorded>(_onPurchaseRecorded);
  }

  final GetPositionsUseCase _getPositions;
  final RecordPurchaseUseCase _recordPurchase;

  void _onChainSynced(
    PortfolioChainSynced event,
    Emitter<PortfolioState> emit,
  ) => emit(PortfolioLoaded(event.positions));

  Future<void> _onRequested(
    PortfolioRequested event,
    Emitter<PortfolioState> emit,
  ) async {
    try {
      final positions = await _getPositions();
      final now = DateTime.now();
      emit(
        PortfolioLoaded(
          positions,
          transactions: [
            for (final (index, position) in positions.indexed)
              PortfolioTransaction(
                company: position.company,
                amount: position.invested,
                tokens: position.tokens,
                source: position.sources.first,
                occurredAt: now.subtract(Duration(hours: index * 3 + 1)),
              ),
          ],
        ),
      );
    } on Failure catch (failure) {
      emit(PortfolioError(failure.message));
    }
  }

  Future<void> _onPurchaseRecorded(
    PurchaseRecorded event,
    Emitter<PortfolioState> emit,
  ) async {
    try {
      final previous = state is PortfolioLoaded
          ? (state as PortfolioLoaded).transactions
          : const <PortfolioTransaction>[];
      final positions = await _recordPurchase(
        company: event.company,
        invested: event.invested,
        tokens: event.tokens,
        source: event.source,
      );
      emit(
        PortfolioLoaded(
          positions,
          transactions: [
            PortfolioTransaction(
              company: event.company,
              amount: event.invested,
              tokens: event.tokens,
              source: event.source,
              occurredAt: DateTime.now(),
            ),
            ...previous,
          ],
        ),
      );
    } on Failure catch (failure) {
      emit(PortfolioError(failure.message));
    }
  }
}
