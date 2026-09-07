import 'package:equatable/equatable.dart';
import 'package:tickerless/features/discovery/domain/entities/company.dart';

/// A company the resolver believes is behind what the user pointed at, with
/// the reason it thinks so.
class CompanyMatch extends Equatable {
  const CompanyMatch({
    required this.company,
    required this.reason,
    required this.confidence,
  });

  final Company company;
  final String reason;

  /// 0–1. Screens render it as a percentage.
  final double confidence;

  @override
  List<Object?> get props => [company, reason, confidence];
}
