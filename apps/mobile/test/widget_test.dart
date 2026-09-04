import 'package:flutter_test/flutter_test.dart';
import 'package:tickerless/src/app.dart';

void main() {
  testWidgets('guest entry opens the Discover experience', (tester) async {
    await tester.pumpWidget(const TickerlessApp());

    expect(find.text('The world is the stock market.'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('What caught\nyour attention\ntoday?'), findsOneWidget);
    expect(find.text('Search anything...'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
  });

  testWidgets('authentication buttons remain visible and enter the app', (
    tester,
  ) async {
    await tester.pumpWidget(const TickerlessApp());

    expect(find.bySemanticsLabel('Continue with Apple'), findsOneWidget);
    expect(find.bySemanticsLabel('Continue with Google'), findsOneWidget);
    expect(find.bySemanticsLabel('Continue with Email'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Your World'), findsOneWidget);
  });

  testWidgets('search journey reaches a Base Sepolia ownership confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(const TickerlessApp());
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

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
}
