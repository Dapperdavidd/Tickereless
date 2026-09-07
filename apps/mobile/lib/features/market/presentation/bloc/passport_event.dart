import 'package:equatable/equatable.dart';
import 'package:tickerless/features/market/domain/entities/chart_range.dart';

abstract class PassportEvent extends Equatable {
  const PassportEvent();

  @override
  List<Object?> get props => [];
}

/// Load the default window and whatever coverage exists.
class PassportOpened extends PassportEvent {
  const PassportOpened();
}

class PassportRangeSelected extends PassportEvent {
  const PassportRangeSelected(this.range);

  final ChartRange range;

  @override
  List<Object?> get props => [range];
}
