import 'package:equatable/equatable.dart';
import 'package:tickerless/features/discovery/domain/entities/company_match.dart';

abstract class LinkState extends Equatable {
  const LinkState();

  @override
  List<Object?> get props => [];
}

class LinkInitial extends LinkState {
  const LinkInitial();
}

class LinkAnalyzing extends LinkState {
  const LinkAnalyzing();
}

class LinkAnalyzed extends LinkState {
  const LinkAnalyzed({required this.url, required this.matches});

  final String url;
  final List<CompanyMatch> matches;

  @override
  List<Object?> get props => [url, matches];
}

class LinkFailed extends LinkState {
  const LinkFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
