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
}
