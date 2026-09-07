import 'package:equatable/equatable.dart';

abstract class LensEvent extends Equatable {
  const LensEvent();

  @override
  List<Object?> get props => [];
}

/// A frame was captured and written to [imagePath].
class LensFrameCaptured extends LensEvent {
  const LensFrameCaptured(this.imagePath);

  final String imagePath;

  @override
  List<Object?> get props => [imagePath];
}

/// No camera on this device, so the screen offers a fixed demo subject
/// instead of pretending recognition happened.
class LensDemoScanRequested extends LensEvent {
  const LensDemoScanRequested(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}
