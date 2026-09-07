import 'package:tickerless/core/di/dependencies.dart';
import 'package:tickerless/features/auth/domain/entities/auth_session.dart';
import 'package:tickerless/features/auth/domain/repositories/auth_repository.dart';
import 'package:tickerless/features/discovery/domain/entities/company_match.dart';
import 'package:tickerless/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:tickerless/features/market/domain/entities/news_article.dart';
import 'package:tickerless/features/market/domain/repositories/news_repository.dart';
import 'package:tickerless/features/wallet/domain/entities/wallet_identity.dart';
import 'package:tickerless/features/wallet/domain/repositories/wallet_repository.dart';

/// Dependencies with nothing behind them that touches a network, a Keychain,
/// or a platform channel — the portfolio keeps its real in-memory source,
/// because that is already a test double in production.
AppDependencies fakeDependencies({
  AuthRepository? auth,
  DiscoveryRepository? discovery,
}) => AppDependencies(
  authRepository: auth ?? FakeAuthRepository(),
  walletRepository: FakeWalletRepository(),
  discoveryRepository: discovery ?? FakeDiscoveryRepository(),
  newsRepository: FakeNewsRepository(),
);

class FakeAuthRepository implements AuthRepository {
  static const session = AuthSession(
    accessToken: 'test-session',
    email: 'owner@example.com',
    userId: 'widget-test-owner',
  );

  @override
  Future<AuthSession> signInWithEmail(String email, String password) async =>
      session;

  @override
  Future<AuthSession> registerWithEmail(String email, String password) async =>
      session;

  @override
  Future<AuthSession> signInWithGoogle() async => session;

  @override
  Future<void> signOut() async {}
}

class FakeWalletRepository implements WalletRepository {
  @override
  Future<WalletIdentity> ensureWallet(String userId) async =>
      const WalletIdentity(
        address: '0x00000000000000000000000000000000000000ff',
      );

  @override
  Future<String> revealPrivateKey(String userId) async => '0x${'a' * 64}';
}

class FakeNewsRepository implements NewsRepository {
  @override
  Future<List<NewsArticle>> forCompany(String ticker) async => [
    NewsArticle(
      headline: '$ticker official newsroom update',
      source: '$ticker Newsroom',
      publishedAt: DateTime(2026, 9, 7),
      url: 'https://example.com/$ticker',
    ),
  ];
}

/// The screens all open on their own worked examples, so the flows under test
/// never need the resolver to answer.
class FakeDiscoveryRepository implements DiscoveryRepository {
  @override
  Future<List<CompanyMatch>> search(String query) async => const [];

  @override
  Future<List<CompanyMatch>> resolveLink(String url) async => const [];

  @override
  Future<List<CompanyMatch>> recognizeFrame(String imagePath) async => const [];

  @override
  Future<List<CompanyMatch>> recognizeText(
    String text, {
    List<String> labels = const [],
  }) async => const [];
}
