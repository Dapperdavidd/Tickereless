import 'package:flutter_test/flutter_test.dart';
import 'package:tickerless/src/app.dart';
import 'package:tickerless/src/services/api_client.dart';
import 'package:tickerless/src/services/wallet_service.dart';
import 'package:tickerless/src/state/auth_state.dart';

void main() {
  setUp(() => walletService = WalletService(store: _MemorySecretStore()));
  tearDown(authState.signOut);

  testWidgets('guest entry opens the Discover experience', (tester) async {
    await tester.pumpWidget(const TickerlessApp());

    expect(find.text('The world is\nthe stock market.'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('What caught\nyour attention\ntoday?'), findsOneWidget);
    expect(find.text('Search anything...'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
  });

  testWidgets('profile lives behind the top avatar, not bottom navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const TickerlessApp());
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('You'), findsNothing);
    expect(find.byTooltip('Open profile'), findsOneWidget);
    await tester.tap(find.byTooltip('Open profile'));
    await tester.pumpAndSettle();

    expect(find.text('Guest mode'), findsOneWidget);
  });

  testWidgets('authentication choices remain visible', (tester) async {
    await tester.pumpWidget(const TickerlessApp());

    expect(find.bySemanticsLabel('Continue with Apple'), findsNothing);
    expect(find.bySemanticsLabel('Continue with Google'), findsOneWidget);
    expect(find.bySemanticsLabel('Continue with email'), findsOneWidget);
    expect(find.bySemanticsLabel('Continue as guest'), findsOneWidget);
  });

  testWidgets('email entry opens working sign-in and registration forms', (
    tester,
  ) async {
    await tester.pumpWidget(const TickerlessApp());

    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    await tester.tap(find.text('New to Tickerless? Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Create your world.'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('onboarding advances through the shared world automatically', (
    tester,
  ) async {
    await tester.pumpWidget(const TickerlessApp());

    expect(find.text('The world is\nthe stock market.'), findsOneWidget);
    expect(find.textContaining('Terms & Conditions'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3300));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Same world.\nMore owners.'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('final onboarding page rewinds through the complete journey', (
    tester,
  ) async {
    await tester.pumpWidget(const TickerlessApp());
    await tester.pump(const Duration(milliseconds: 3300));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 3300));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Turn attention\ninto ownership.'), findsOneWidget);
    expect(find.text('Scan anything'), findsOneWidget);
    expect(find.text('Search naturally'), findsOneWidget);
    expect(find.text('Paste a link'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3300));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('The world is\nthe stock market.'), findsOneWidget);
  });

  testWidgets('search journey reaches a Base Sepolia ownership confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(const TickerlessApp());
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    await authState.authenticate(
      const AuthSession(
        accessToken: 'test-session',
        email: 'owner@example.com',
        userId: 'widget-test-owner',
      ),
    );

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Meta Platforms'), findsOneWidget);

    await tester.tap(find.text('View Company →'));
    await tester.pumpAndSettle();
    expect(find.text('Company Passport'), findsOneWidget);

    final ownButton = find.text('Own Meta Platforms');
    await tester.ensureVisible(ownButton);
    await tester.tap(ownButton);
    await tester.pumpAndSettle();
    expect(find.text('Base Sepolia'), findsOneWidget);

    final reviewButton = find.text('Review Purchase');
    await tester.ensureVisible(reviewButton);
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();
    expect(find.text('You now own\nMeta Platforms.'), findsOneWidget);
    expect(find.text('on Base Sepolia'), findsOneWidget);
  });

  testWidgets('guest discovery stops at the purchase sign-in gate', (
    tester,
  ) async {
    await tester.pumpWidget(const TickerlessApp());
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Company →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Own Meta Platforms'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to own a piece'), findsOneWidget);
    expect(find.text('Review Purchase'), findsNothing);
  });
}

class _MemorySecretStore implements WalletSecretStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
