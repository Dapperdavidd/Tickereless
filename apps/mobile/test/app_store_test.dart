import 'package:flutter_test/flutter_test.dart';
import 'package:tickerless/src/models/company.dart';
import 'package:tickerless/src/state/app_store.dart';

void main() {
  test('purchase aggregates ownership and discovery context', () {
    final store = AppStore();
    store.record(DemoCompanies.meta, 5, .01, 'Threads · Search');

    final meta = store.positions.singleWhere(
      (position) => position.company.ticker == 'META',
    );
    expect(meta.invested, 10);
    expect(meta.tokens, .02);
    expect(meta.sources, contains('Threads · Search'));
    expect(store.total, 32);
  });
}
