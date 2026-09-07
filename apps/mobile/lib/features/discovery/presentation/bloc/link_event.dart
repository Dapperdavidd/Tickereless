import 'package:equatable/equatable.dart';

abstract class LinkEvent extends Equatable {
  const LinkEvent();

  @override
  List<Object?> get props => [];
}

class LinkSubmitted extends LinkEvent {
  const LinkSubmitted(this.url);

  final String url;

  @override
  List<Object?> get props => [url];
}
