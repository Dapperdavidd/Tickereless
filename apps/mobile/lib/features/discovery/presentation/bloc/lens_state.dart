import 'package:equatable/equatable.dart';
import 'package:tickerless/features/discovery/domain/entities/company_match.dart';

abstract class LensState extends Equatable {
  const LensState();

  @override
  List<Object?> get props => [];
}

class LensIdle extends LensState {
  const LensIdle();
}

class LensScanning extends LensState {
  const LensScanning();
}

class LensMatched extends LensState {
  const LensMatched(this.match);

  final CompanyMatch match;

  @override
  List<Object?> get props => [match];
}

/// The scan completed and found nothing the resolver recognises.
class LensUnmatched extends LensState {
  const LensUnmatched();
}

class LensFailed extends LensState {
  const LensFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
