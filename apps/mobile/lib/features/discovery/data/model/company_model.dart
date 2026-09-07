import 'package:tickerless/features/discovery/domain/entities/company.dart';

class CompanyModel extends Company {
  const CompanyModel({
    required super.name,
    required super.ticker,
    required super.symbol,
    required super.description,
    required super.products,
    required super.price,
    required super.change,
  });

  /// `json` is the resolver's `company` object; `asset` is the Base Sepolia
  /// listing, which the backend nests either alongside or inside it.
  factory CompanyModel.fromJson(Map<String, dynamic> json, {
    Map<String, dynamic>? asset,
  }) {
    final ticker = json['ticker'].toString();
    return CompanyModel(
      name: json['name'].toString(),
      ticker: ticker,
      symbol: asset?['symbol']?.toString() ?? ticker,
      description: json['description']?.toString() ?? '',
      products: (json['aliases'] as List<dynamic>? ?? const [])
          .take(3)
          .map((alias) => alias.toString())
          .toList(),
      price: double.tryParse(asset?['price_usdc']?.toString() ?? '') ?? 0,
      change: 0,
    );
  }
}
