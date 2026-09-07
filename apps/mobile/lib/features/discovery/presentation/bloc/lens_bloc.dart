import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/features/discovery/domain/entities/company_match.dart';
import 'package:tickerless/features/discovery/domain/usecases/recognize_frame.dart';
import 'package:tickerless/features/discovery/domain/usecases/recognize_text.dart';
import 'package:tickerless/features/discovery/presentation/bloc/lens_event.dart';
import 'package:tickerless/features/discovery/presentation/bloc/lens_state.dart';

class LensBloc extends Bloc<LensEvent, LensState> {
  LensBloc({
    required RecognizeFrameUseCase recognizeFrame,
    required RecognizeTextUseCase recognizeText,
  }) : _recognizeFrame = recognizeFrame,
       _recognizeText = recognizeText,
       super(const LensIdle()) {
    on<LensFrameCaptured>(
      (event, emit) => _scan(emit, () => _recognizeFrame(event.imagePath)),
    );
    on<LensDemoScanRequested>(
      (event, emit) => _scan(emit, () => _recognizeText(event.text)),
    );
  }

  final RecognizeFrameUseCase _recognizeFrame;
  final RecognizeTextUseCase _recognizeText;

  Future<void> _scan(
    Emitter<LensState> emit,
    Future<List<CompanyMatch>> Function() recognize,
  ) async {
    emit(const LensScanning());
    try {
      final matches = await recognize();
      emit(matches.isEmpty ? const LensUnmatched() : LensMatched(matches.first));
    } on Failure catch (failure) {
      emit(LensFailed(failure.message));
    }
  }
}
