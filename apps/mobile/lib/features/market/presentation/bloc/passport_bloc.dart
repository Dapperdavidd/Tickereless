import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/features/market/domain/usecases/get_company_news.dart';
import 'package:tickerless/features/market/domain/usecases/get_price_series.dart';
import 'package:tickerless/features/market/presentation/bloc/passport_event.dart';
import 'package:tickerless/features/market/presentation/bloc/passport_state.dart';

/// Owns one company's chart window and coverage, for as long as its passport
/// is on screen.
class PassportBloc extends Bloc<PassportEvent, PassportState> {
  PassportBloc({
    required GetPriceSeriesUseCase getPriceSeries,
    required GetCompanyNewsUseCase getCompanyNews,
    required this.ticker,
    required this.anchorPrice,
  }) : _getPriceSeries = getPriceSeries,
       _getCompanyNews = getCompanyNews,
       super(const PassportState()) {
    on<PassportOpened>(_onOpened);
    on<PassportRangeSelected>(_onRangeSelected);
  }

  final GetPriceSeriesUseCase _getPriceSeries;
  final GetCompanyNewsUseCase _getCompanyNews;
  final String ticker;
  final double anchorPrice;

  Future<void> _onOpened(
    PassportOpened event,
    Emitter<PassportState> emit,
  ) async {
    try {
      // Started together, awaited separately: the two are independent, and
      // this keeps both results typed.
      final series = await _getPriceSeries(
        ticker: ticker,
        anchorPrice: anchorPrice,
        range: state.range,
      );
      var articles = state.articles;
      try {
        articles = await _getCompanyNews(ticker);
      } catch (_) {
        // A newsroom outage must not take down the company passport.
      }
      emit(
        state.copyWith(series: series, articles: articles, isLoading: false),
      );
    } on Failure catch (failure) {
      emit(state.copyWith(isLoading: false, errorMessage: failure.message));
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Company details are temporarily unavailable.',
        ),
      );
    }
  }

  Future<void> _onRangeSelected(
    PassportRangeSelected event,
    Emitter<PassportState> emit,
  ) async {
    if (event.range == state.range) return;
    emit(state.copyWith(range: event.range));
    try {
      emit(
        state.copyWith(
          series: await _getPriceSeries(
            ticker: ticker,
            anchorPrice: anchorPrice,
            range: event.range,
          ),
        ),
      );
    } on Failure catch (failure) {
      emit(state.copyWith(errorMessage: failure.message));
    }
  }
}
