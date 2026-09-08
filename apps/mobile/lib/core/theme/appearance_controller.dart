import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppearanceController extends ChangeNotifier {
  AppearanceController._({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    _restore();
  }

  static final AppearanceController _instance = AppearanceController._();
  factory AppearanceController() => _instance;

  static const _themeKey = 'tickerless_theme_mode';
  static const _newsKey = 'tickerless_news_notifications';
  final FlutterSecureStorage _storage;

  ThemeMode themeMode = ThemeMode.dark;
  bool newsNotifications = false;

  Future<void> _restore() async {
    try {
      final values = await Future.wait([
        _storage.read(key: _themeKey),
        _storage.read(key: _newsKey),
      ]);
      themeMode = values.first == 'light' ? ThemeMode.light : ThemeMode.dark;
      newsNotifications = values.last == 'true';
      notifyListeners();
    } catch (_) {
      // Tests and unsupported platforms may not expose secure storage.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _storage.write(
      key: _themeKey,
      value: mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  Future<void> setNewsNotifications(bool enabled) async {
    newsNotifications = enabled;
    notifyListeners();
    await _storage.write(key: _newsKey, value: enabled.toString());
  }
}
