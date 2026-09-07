import 'package:tickerless/core/network/api_client.dart';
import 'package:tickerless/features/auth/data/datasource/auth_local_datasource.dart';
import 'package:tickerless/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:tickerless/features/auth/data/datasource/google_sign_in_datasource.dart';
import 'package:tickerless/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tickerless/features/auth/domain/repositories/auth_repository.dart';
import 'package:tickerless/features/auth/domain/usecases/register_with_email.dart';
import 'package:tickerless/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:tickerless/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:tickerless/features/auth/domain/usecases/sign_out.dart';
import 'package:tickerless/features/discovery/data/datasource/discovery_remote_datasource.dart';
import 'package:tickerless/features/discovery/data/datasource/frame_analysis_datasource.dart';
import 'package:tickerless/features/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:tickerless/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:tickerless/features/discovery/domain/usecases/recognize_frame.dart';
import 'package:tickerless/features/discovery/domain/usecases/recognize_text.dart';
import 'package:tickerless/features/discovery/domain/usecases/resolve_link.dart';
import 'package:tickerless/features/discovery/domain/usecases/search_companies.dart';
import 'package:tickerless/features/portfolio/data/datasource/portfolio_local_datasource.dart';
import 'package:tickerless/features/portfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:tickerless/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:tickerless/features/portfolio/domain/usecases/get_positions.dart';
import 'package:tickerless/features/portfolio/domain/usecases/record_purchase.dart';
import 'package:tickerless/features/wallet/data/datasource/wallet_local_datasource.dart';
import 'package:tickerless/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:tickerless/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:tickerless/features/wallet/domain/usecases/ensure_wallet.dart';
import 'package:tickerless/features/wallet/domain/usecases/reveal_private_key.dart';

/// The composition root: the one place that knows which implementation backs
/// each abstraction.
///
/// Deliberately a plain object rather than a service locator — a test builds
/// one with fakes and passes it to the app, instead of registering globals
/// that then have to be unregistered.
class AppDependencies {
  AppDependencies({
    ApiClient? apiClient,
    AuthRepository? authRepository,
    WalletRepository? walletRepository,
    DiscoveryRepository? discoveryRepository,
    PortfolioRepository? portfolioRepository,
  }) : this._resolved(
         apiClient: apiClient ??= ApiClient(),
         authRepository:
             authRepository ??
             AuthRepositoryImpl(
               remoteDataSource: AuthRemoteDataSourceImpl(client: apiClient),
               localDataSource: AuthLocalDataSourceImpl(),
               googleDataSource: GoogleSignInDataSourceImpl(),
             ),
         walletRepository:
             walletRepository ??
             WalletRepositoryImpl(
               localDataSource: WalletLocalDataSourceImpl(),
             ),
         discoveryRepository:
             discoveryRepository ??
             DiscoveryRepositoryImpl(
               remoteDataSource: DiscoveryRemoteDataSourceImpl(
                 client: apiClient,
               ),
               frameDataSource: const PlatformFrameAnalysisDataSource(),
             ),
         portfolioRepository:
             portfolioRepository ??
             PortfolioRepositoryImpl(
               localDataSource: InMemoryPortfolioDataSource(),
             ),
       );

  AppDependencies._resolved({
    required this.apiClient,
    required AuthRepository authRepository,
    required WalletRepository walletRepository,
    required DiscoveryRepository discoveryRepository,
    required PortfolioRepository portfolioRepository,
  }) : signInWithEmail = SignInWithEmailUseCase(repository: authRepository),
       registerWithEmail = RegisterWithEmailUseCase(
         repository: authRepository,
       ),
       signInWithGoogle = SignInWithGoogleUseCase(repository: authRepository),
       signOut = SignOutUseCase(repository: authRepository),
       ensureWallet = EnsureWalletUseCase(repository: walletRepository),
       revealPrivateKey = RevealPrivateKeyUseCase(
         repository: walletRepository,
       ),
       searchCompanies = SearchCompaniesUseCase(
         repository: discoveryRepository,
       ),
       resolveLink = ResolveLinkUseCase(repository: discoveryRepository),
       recognizeFrame = RecognizeFrameUseCase(repository: discoveryRepository),
       recognizeText = RecognizeTextUseCase(repository: discoveryRepository),
       getPositions = GetPositionsUseCase(repository: portfolioRepository),
       recordPurchase = RecordPurchaseUseCase(repository: portfolioRepository);

  final ApiClient apiClient;

  final SignInWithEmailUseCase signInWithEmail;
  final RegisterWithEmailUseCase registerWithEmail;
  final SignInWithGoogleUseCase signInWithGoogle;
  final SignOutUseCase signOut;

  final EnsureWalletUseCase ensureWallet;
  final RevealPrivateKeyUseCase revealPrivateKey;

  final SearchCompaniesUseCase searchCompanies;
  final ResolveLinkUseCase resolveLink;
  final RecognizeFrameUseCase recognizeFrame;
  final RecognizeTextUseCase recognizeText;

  final GetPositionsUseCase getPositions;
  final RecordPurchaseUseCase recordPurchase;
}
