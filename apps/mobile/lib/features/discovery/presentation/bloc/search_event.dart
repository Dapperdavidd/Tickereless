import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchSubmitted extends SearchEvent {
  const SearchSubmitted(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
