import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a bloc stream to `GoRouter.refreshListenable`, so a change in
/// access re-runs the redirect instead of leaving the user on a screen they
/// are no longer allowed to see.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
