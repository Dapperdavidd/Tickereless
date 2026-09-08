/// Where the Rust resolver/auth backend lives.
///
/// Overridable at build time so a device build can point at a LAN or staging
/// host without a code change:
/// `flutter run --dart-define=TICKERLESS_API_URL=http://192.168.1.10:8080`.
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'TICKERLESS_API_URL',
    defaultValue: 'https://api-production-b1d0b.up.railway.app',
  );

  static const requestTimeout = Duration(seconds: 12);
}
