import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/features/discovery/domain/usecases/resolve_link.dart';
import 'package:tickerless/features/discovery/presentation/bloc/link_event.dart';
import 'package:tickerless/features/discovery/presentation/bloc/link_state.dart';

class LinkBloc extends Bloc<LinkEvent, LinkState> {
  LinkBloc({required ResolveLinkUseCase resolveLink})
    : _resolveLink = resolveLink,
      super(const LinkInitial()) {
    on<LinkSubmitted>(_onSubmitted);
  }

  final ResolveLinkUseCase _resolveLink;

  Future<void> _onSubmitted(LinkSubmitted event, Emitter<LinkState> emit) async {
    final url = event.url.trim();
    if (url.isEmpty) return;

    emit(const LinkAnalyzing());
    try {
      emit(LinkAnalyzed(url: url, matches: await _resolveLink(url)));
    } on Failure catch (failure) {
      emit(LinkFailed(failure.message));
    }
  }
}
