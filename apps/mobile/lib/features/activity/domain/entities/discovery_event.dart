import 'package:equatable/equatable.dart';
import 'package:tickerless/features/discovery/domain/entities/discovery_source.dart';

/// Something the user looked at, whether or not they ended up owning it.
class DiscoveryEvent extends Equatable {
  const DiscoveryEvent({
    required this.title,
    required this.company,
    required this.symbol,
    required this.source,
    required this.owned,
    required this.day,
  });

  /// What the user actually pointed at — a product, a phrase, an article.
  final String title;
  final String company;
  final String symbol;
  final DiscoverySource source;
  final bool owned;

  /// Section heading the event files under, e.g. `Today`.
  final String day;

  @override
  List<Object?> get props => [title, company, symbol, source, owned, day];
}
