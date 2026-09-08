import 'package:equatable/equatable.dart';
import 'package:tickerless/features/discovery/domain/entities/company_match.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// Nothing asked yet — no result is implied until the resolver answers.
class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  const SearchLoaded({required this.query, required this.matches});

  final String query;
  final List<CompanyMatch> matches;

  @override
  List<Object?> get props => [query, matches];
}

class SearchFailed extends SearchState {
  const SearchFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
