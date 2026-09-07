import 'package:flutter/services.dart';
import 'package:tickerless/core/error/exceptions.dart';

/// Text and visual labels read off a captured frame by the platform's own
/// vision framework.
class FrameAnalysis {
  const FrameAnalysis({required this.text, required this.labels});

  final String text;
  final List<String> labels;

  bool get isEmpty => text.trim().isEmpty && labels.isEmpty;
}

abstract interface class FrameAnalysisDataSource {
  Future<FrameAnalysis> analyze(String imagePath);
}

class PlatformFrameAnalysisDataSource implements FrameAnalysisDataSource {
  const PlatformFrameAnalysisDataSource({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.tickerless/vision');

  final MethodChannel _channel;

  @override
  Future<FrameAnalysis> analyze(String imagePath) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'analyzeImage',
        {'path': imagePath},
      );
      return FrameAnalysis(
        text: result?['text']?.toString() ?? '',
        labels: (result?['labels'] as List<dynamic>? ?? const [])
            .map((label) => label.toString())
            .toList(),
      );
    } on PlatformException catch (error) {
      throw ImageAnalysisException(
        error.message ?? 'Could not read the frame.',
      );
    }
  }
}
