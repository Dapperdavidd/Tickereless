import 'package:tickerless/core/error/exceptions.dart';
import 'package:tickerless/core/error/failures.dart';
import 'package:tickerless/core/network/network_error.dart';
import 'package:tickerless/features/discovery/data/datasource/discovery_remote_datasource.dart';
import 'package:tickerless/features/discovery/data/datasource/frame_analysis_datasource.dart';
import 'package:tickerless/features/discovery/domain/entities/company_match.dart';
import 'package:tickerless/features/discovery/domain/repositories/discovery_repository.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  const DiscoveryRepositoryImpl({
    required DiscoveryRemoteDataSource remoteDataSource,
    required FrameAnalysisDataSource frameDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _frameDataSource = frameDataSource;

  final DiscoveryRemoteDataSource _remoteDataSource;
  final FrameAnalysisDataSource _frameDataSource;

  @override
  Future<List<CompanyMatch>> search(String query) =>
      _resolve(() => _remoteDataSource.search(query));

  @override
  Future<List<CompanyMatch>> resolveLink(String url) =>
      _resolve(() => _remoteDataSource.resolveLink(url));

  @override
  Future<List<CompanyMatch>> recognizeText(
    String text, {
    List<String> labels = const [],
  }) => _resolve(() => _remoteDataSource.recognize(text, labels));

  @override
  Future<List<CompanyMatch>> recognizeFrame(String imagePath) =>
      _resolve(() async {
        final analysis = await _frameDataSource.analyze(imagePath);
        // Nothing legible in the frame is a normal outcome, not a failure —
        // the resolver would only answer with an empty list anyway.
        if (analysis.isEmpty) return const [];
        return _remoteDataSource.recognize(analysis.text, analysis.labels);
      });

  Future<List<CompanyMatch>> _resolve(
    Future<List<CompanyMatch>> Function() request,
  ) async {
    try {
      return await request();
    } on ApiException catch (error) {
      throw ResolverFailure(error.message);
    } on ImageAnalysisException catch (error) {
      throw ResolverFailure(error.message);
    } catch (error) {
      throw ResolverFailure(friendlyNetworkError(error));
    }
  }
}
