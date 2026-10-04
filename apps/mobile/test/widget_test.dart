import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickerless/app.dart';
import 'package:tickerless/features/auth/domain/entities/auth_session.dart';
import 'package:tickerless/features/auth/domain/repositories/auth_repository.dart';
import 'package:tickerless/features/wallet/data/chain_gateway.dart';

import 'support/fake_dependencies.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    ChainGateway? chainGateway,
  }) async {
    await tester.pumpWidget(
      TickerlessApp(dependencies: fakeDependencies(chainGateway: chainGateway)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();
  }

  /// The gate at the passport is the only thing separating guests from
  /// owners, so most flows start by getting past the door one way or another.
  Future<void> enterAsGuest(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester, {ChainGateway? chainGateway}) async {
    await pumpApp(tester, chainGateway: chainGateway);
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'owner@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secure-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue with email'));
    await tester.pumpAndSettle();
  }

  testWidgets('guest entry opens the Discover experience', (tester) async {
    await enterAsGuest(tester);

    // Discover is a grid of companies under one line of chrome, so the
    // landmarks are the section bar and the affordances, not a hero heading.
    expect(find.text('Featured'), findsOneWidget);
    expect(find.text('NVIDIA'), findsOneWidget);
    expect(find.byTooltip('Search'), findsOneWidget);
    expect(find.byTooltip('Open Lens'), findsOneWidget);
  });

  testWidgets('profile lives behind the top avatar, not bottom navigation', (
    tester,
  ) async {
    await enterAsGuest(tester);

    expect(find.text('You'), findsNothing);
    expect(find.byTooltip('Open profile'), findsOneWidget);

    await tester.tap(find.byTooltip('Open profile'));
    await tester.pumpAndSettle();

    expect(find.text('Guest mode'), findsOneWidget);
  });

  testWidgets('guest upgrade offers both email and Google', (tester) async {
    await enterAsGuest(tester);
    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in or create account'));
    await tester.pumpAndSettle();

    expect(find.text('Make it yours.'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('authentication choices remain visible', (tester) async {
    await pumpApp(tester);

    expect(find.bySemanticsLabel('Continue with Apple'), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('a returning account never sees onboarding during restore', (
    tester,
  ) async {
    final auth = _DelayedRestoreAuthRepository();
    await tester.pumpWidget(
      TickerlessApp(dependencies: fakeDependencies(auth: auth)),
    );

    expect(find.text('The world is\nthe stock market.'), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);

    auth.complete();
    await tester.pumpAndSettle();

    expect(find.text('Featured'), findsOneWidget);
    expect(find.text('The world is\nthe stock market.'), findsNothing);
  });

  testWidgets('email entry opens working sign-in and registration forms', (
    tester,
  ) async {
    await pumpApp(tester);

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
    await pumpApp(tester);

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
    await pumpApp(tester);
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

  testWidgets('signing in provisions a wallet and reaches Discover', (
    tester,
  ) async {
    await signIn(tester);

    expect(find.text('Featured'), findsOneWidget);

    await tester.tap(find.byTooltip('Open profile'));
    await tester.pumpAndSettle();

    expect(find.text('owner@example.com'), findsOneWidget);
    expect(find.text('XsbEhL…JzJp'), findsWidgets);
  });

  testWidgets('wallet balance text toggles privacy and Receive fits', (
    tester,
  ) async {
    await signIn(tester);
    await tester.tap(find.bySemanticsLabel('Wallet'));
    await tester.pumpAndSettle();

    final visibleBalance = find.bySemanticsLabel(
      RegExp(r'Wallet balance 15\.00 dollars'),
    );
    expect(visibleBalance, findsOneWidget);
    await tester.tap(find.text(r'$15.00').first);
    await tester.pump();
    final hiddenBalance = find.bySemanticsLabel(
      'Hidden wallet balance. Double tap to show.',
    );
    expect(hiddenBalance, findsOneWidget);
    await tester.tap(find.text('••••••').first);
    await tester.pump();
    expect(visibleBalance, findsOneWidget);

    await tester.tap(find.text('Receive'));
    await tester.pumpAndSettle();
    expect(find.text('Receive on Solana Devnet'), findsOneWidget);
    expect(find.text('Copy address'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
  });

  testWidgets('search reaches a verified Solana instrument passport', (
    tester,
  ) async {
    await signIn(tester);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'company behind Instagram');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Meta Platforms'), findsOneWidget);

    await tester.tap(find.text('View Company →'));
    await tester.pumpAndSettle();
    // The passport leads with the price and the chart, not a page title.
    expect(find.text(r'$730.38'), findsOneWidget);
    expect(find.text('Demo series · not market data'), findsOneWidget);
    expect(find.text('Solana mainnet'), findsOneWidget);
    expect(find.text('Tokenized stock'), findsOneWidget);
    expect(find.text('Solana access coming soon'), findsOneWidget);
  });

  for (final asset in const [
    (query: 'AAPL', company: 'Apple', symbol: 'AAPLx'),
    (query: 'NVDA', company: 'NVIDIA', symbol: 'NVDAx'),
    (query: 'META', company: 'Meta Platforms', symbol: 'METAx'),
    (query: 'GOOGL', company: 'Alphabet', symbol: 'GOOGLx'),
    (query: 'MSFT', company: 'Microsoft', symbol: 'MSFTx'),
  ]) {
    testWidgets(
      '${asset.query} exposes its verified instrument without a fake trade',
      (tester) async {
        await signIn(tester);

        await tester.tap(find.byTooltip('Search'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), asset.query);
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        expect(find.text(asset.company), findsOneWidget);

        await tester.tap(find.text('View Company →'));
        await tester.pumpAndSettle();
        expect(find.text(asset.symbol), findsOneWidget);
        expect(find.text('Solana access coming soon'), findsOneWidget);
        expect(find.text('Buy with USDC'), findsNothing);
      },
    );
  }

  testWidgets('World is a company news hub', (tester) async {
    await enterAsGuest(tester);
    await tester.tap(find.bySemanticsLabel('World'));
    await tester.pumpAndSettle();

    expect(find.text('World'), findsWidgets);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.textContaining('official newsroom update'), findsWidgets);
  });

  testWidgets('guest discovery stops at the Solana execution gate', (
    tester,
  ) async {
    await enterAsGuest(tester);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'company behind Instagram');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Company →'));
    await tester.pumpAndSettle();
    expect(find.text('Solana access coming soon'), findsOneWidget);
    expect(find.text('Sign in to own a piece'), findsNothing);
    expect(find.text('Review Purchase'), findsNothing);
  });

  testWidgets('signing out returns to the door', (tester) async {
    await signIn(tester);
    await tester.tap(find.byTooltip('Open profile'));
    await tester.pumpAndSettle();

    // Sign Out sits at the bottom of a long list, so it is not built until
    // the list scrolls that far.
    final signOut = find.text('Sign Out');
    await tester.scrollUntilVisible(
      signOut,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(signOut);
    await tester.pumpAndSettle();

    expect(find.text('The world is\nthe stock market.'), findsOneWidget);
  });
}

class _DelayedRestoreAuthRepository implements AuthRepository {
  final _restore = Completer<AuthSession?>();

  void complete() => _restore.complete(FakeAuthRepository.session);

  @override
  Future<AuthSession?> restoreSession() => _restore.future;

  @override
  Future<AuthSession> registerWithEmail(String email, String password) async =>
      FakeAuthRepository.session;

  @override
  Future<AuthSession> signInWithEmail(String email, String password) async =>
      FakeAuthRepository.session;

  @override
  Future<AuthSession> signInWithGoogle() async => FakeAuthRepository.session;

  @override
  Future<void> signOut() async {}
}
