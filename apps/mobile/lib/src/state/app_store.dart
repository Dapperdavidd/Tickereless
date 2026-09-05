import 'package:flutter/foundation.dart';

import '../models/company.dart';

final appStore = AppStore();

class AppStore extends ChangeNotifier {
  final Map<String, OwnedPosition> _positions = {
    'AAPL': OwnedPosition(
      company: DemoCompanies.apple,
      invested: 14,
      tokens: 14 / 214.32,
      sources: ['iPhone · Lens'],
    ),
    'NVDA': OwnedPosition(
      company: DemoCompanies.nvidia,
      invested: 8,
      tokens: 8 / 180,
      sources: ['AI article · Link'],
    ),
    'META': const OwnedPosition(
      company: DemoCompanies.meta,
      invested: 5,
      tokens: .01,
      sources: ['Instagram · Search'],
    ),
  };

  List<OwnedPosition> get positions => _positions.values.toList();
  double get total => positions.fold(0, (sum, item) => sum + item.invested);
  int get discoveryCount =>
      positions.fold(0, (sum, item) => sum + item.sources.length);

  void record(Company company, double amount, double tokens, String source) {
    final current = _positions[company.ticker];
    _positions[company.ticker] = current == null
        ? OwnedPosition(
            company: company,
            invested: amount,
            tokens: tokens,
            sources: [source],
          )
        : OwnedPosition(
            company: company,
            invested: current.invested + amount,
            tokens: current.tokens + tokens,
            sources: {...current.sources, source}.toList(),
          );
    notifyListeners();
  }
}

class OwnedPosition {
  const OwnedPosition({
    required this.company,
    required this.invested,
    required this.tokens,
    required this.sources,
  });
  final Company company;
  final double invested;
  final double tokens;
  final List<String> sources;
}
