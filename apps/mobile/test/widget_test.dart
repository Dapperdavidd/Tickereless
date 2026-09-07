import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickerless/app.dart';

import 'support/fake_dependencies.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) =>
      tester.pumpWidget(TickerlessApp(dependencies: fakeDependencies()));

  /// The gate at the passport is the only thing separating guests from
  /// owners, so most flows start by getting past the door one way or another.
  Future<void> enterAsGuest(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester) async {
    await pumpApp(tester);
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

  testWidgets('authentication choices remain visible', (tester) async {
    await pumpApp(tester);

    expect(find.bySemanticsLabel('Continue with Apple'), findsNothing);
    expect(find.bySemanticsLabel('Continue with Google'), findsOneWidget);
    expect(find.bySemanticsLabel('Continue with email'), findsOneWidget);
    expect(find.bySemanticsLabel('Continue as guest'), findsOneWidget);
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
    expect(find.text('0x0000…00ff'), findsWidgets);
  });

  testWidgets('search journey reaches a Base Sepolia ownership confirmation', (
    tester,
  ) async {
    await signIn(tester);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Meta Platforms'), findsOneWidget);

    await tester.tap(find.text('View Company →'));
    await tester.pumpAndSettle();
    // The passport leads with the price and the chart, not a page title.
    expect(find.text(r'$500.00'), findsOneWidget);
    expect(find.text('Demo series · not market data'), findsOneWidget);

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

  testWidgets('a purchase lands in Wallet transaction history', (tester) async {
    await signIn(tester);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Company →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Own Meta Platforms'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review Purchase'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View in Wallet'));
    await tester.pumpAndSettle();

    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text(r'$32.00'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recent Transactions'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Recent Transactions'), findsOneWidget);
    expect(find.text('Bought tMETAc'), findsWidgets);
  });

  testWidgets('World is a company news hub', (tester) async {
    await enterAsGuest(tester);
    await tester.tap(find.bySemanticsLabel('World'));
    await tester.pumpAndSettle();

    expect(find.text('World'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.textContaining('official newsroom update'), findsWidgets);
  });

  testWidgets('guest discovery stops at the purchase sign-in gate', (
    tester,
  ) async {
    await enterAsGuest(tester);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Company →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Own Meta Platforms'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to own a piece'), findsOneWidget);
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
