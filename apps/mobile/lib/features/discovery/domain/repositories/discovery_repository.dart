import 'package:tickerless/features/discovery/domain/entities/company_match.dart';

abstract class DiscoveryRepository {
  Future<List<CompanyMatch>> search(String query);
  Future<List<CompanyMatch>> resolveLink(String url);

  /// Reads a captured frame with the platform's vision framework, then asks
  /// the resolver about whatever it found. Empty when the frame held nothing
  /// recognisable.
  Future<List<CompanyMatch>> recognizeFrame(String imagePath);

  /// Text and visual labels that were obtained some other way — the simulator
  /// demo path, which has no camera to capture from.
  Future<List<CompanyMatch>> recognizeText(
    String text, {
    List<String> labels = const [],
  });
}
