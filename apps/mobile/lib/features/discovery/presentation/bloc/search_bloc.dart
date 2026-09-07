import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/features/discovery/domain/usecases/search_companies.dart';
import 'package:tickerless/features/discovery/presentation/bloc/search_event.dart';
import 'package:tickerless/features/discovery/presentation/bloc/search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required SearchCompaniesUseCase searchCompanies})
    : _searchCompanies = searchCompanies,
      super(const SearchInitial()) {
    on<SearchSubmitted>(_onSubmitted);
  }

  final SearchCompaniesUseCase _searchCompanies;

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    emit(const SearchLoading());
    try {
      emit(SearchLoaded(query: query, matches: await _searchCompanies(query)));
    } on Failure catch (failure) {
      emit(SearchFailed(failure.message));
    }
  }
}
