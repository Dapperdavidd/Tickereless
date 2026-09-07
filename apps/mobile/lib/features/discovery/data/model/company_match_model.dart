import 'package:tickerless/features/discovery/data/model/company_model.dart';
import 'package:tickerless/features/discovery/domain/entities/company_match.dart';

class CompanyMatchModel extends CompanyMatch {
  const CompanyMatchModel({
    required super.company,
    required super.reason,
    required super.confidence,
  });

  factory CompanyMatchModel.fromJson(Map<String, dynamic> json) {
    final company = json['company'] as Map<String, dynamic>;
    return CompanyMatchModel(
      company: CompanyModel.fromJson(
        company,
        asset: (json['asset'] ?? company['asset']) as Map<String, dynamic>?,
      ),
      reason: json['reason']?.toString() ?? 'Matched by the Tickerless resolver',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}
