import 'package:equatable/equatable.dart';

/// A company as the resolver describes it.
///
/// Deliberately free of Flutter types: brand colour and icon are presentation
/// concerns and live in `presentation/brand_palette.dart`.
class Company extends Equatable {
  const Company({
    required this.name,
    required this.ticker,
    required this.symbol,
    required this.description,
    required this.products,
    required this.price,
    required this.change,
  });

  final String name;
  final String ticker;

  /// The tokenised demo equity, e.g. `tAAPLc`.
  final String symbol;
  final String description;
  final List<String> products;
  final double price;
  final double change;

  @override
  List<Object?> get props => [
    name,
    ticker,
    symbol,
    description,
    products,
    price,
    change,
  ];
}
