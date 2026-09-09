import 'package:flutter_test/flutter_test.dart';
import 'package:tickerless/features/discovery/domain/usecases/recognize_frame.dart';
import 'package:tickerless/features/discovery/domain/usecases/recognize_text.dart';
import 'package:tickerless/features/discovery/presentation/bloc/lens_bloc.dart';
import 'package:tickerless/features/discovery/presentation/bloc/lens_event.dart';
import 'package:tickerless/features/discovery/presentation/bloc/lens_state.dart';

import '../../support/fake_dependencies.dart';

void main() {
  test('a previous Lens match resets to the fresh scanning state', () async {
    final repository = FakeDiscoveryRepository();
    final bloc = LensBloc(
      recognizeFrame: RecognizeFrameUseCase(repository: repository),
      recognizeText: RecognizeTextUseCase(repository: repository),
    );
    addTearDown(bloc.close);

    final matched = bloc.stream.firstWhere((state) => state is LensMatched);
    bloc.add(const LensDemoScanRequested('Apple logo'));
    expect(await matched, isA<LensMatched>());

    final reset = bloc.stream.firstWhere((state) => state is LensIdle);
    bloc.add(const LensReset());
    expect(await reset, isA<LensIdle>());
  });
}
