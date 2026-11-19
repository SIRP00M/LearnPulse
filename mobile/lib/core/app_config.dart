import 'dart:convert';

/// Build-time configuration (`--dart-define-from-file`). Only public client values are accepted:
/// a Supabase URL and the publishable (anon) key. Privileged keys are refused at startup.
class AppConfig {
  const AppConfig({required this.supabaseUrl, required this.publishableKey});

  final String supabaseUrl;
  final String publishableKey;

  /// Deep link registered in AndroidManifest and in the Supabase redirect allow-list.
  static const authRedirect = 'learnpulse://auth-callback';

  /// Mirrors pubspec.yaml `version:` (a test keeps them equal); shown on the About screen.
  static const appVersion = '0.1.0-beta.1+2';

  /// Optional: pre-fills the Presenter Demo sign-in email (an address is not a secret; no password is ever built in).
  static const demoPresenterEmail = String.fromEnvironment('DEMO_PRESENTER_EMAIL');

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static AppConfig fromEnvironment() =>
      AppConfig(supabaseUrl: _url, publishableKey: _key);

  /// Returns a human-readable problem, or null when the configuration is usable.
  String? validate() {
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      return 'SUPABASE_URL is missing or invalid. Build with --dart-define-from-file.';
    }
    const localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};
    if (uri.scheme != 'https' &&
        !(uri.scheme == 'http' && localHosts.contains(uri.host))) {
      return 'SUPABASE_URL must use https (http is allowed only for a local stack).';
    }
    if (publishableKey.isEmpty) {
      return 'SUPABASE_PUBLISHABLE_KEY is missing.';
    }
    return keyProblem(publishableKey);
  }

  /// Rejects secret keys and service_role JWTs; they must never ship in a client.
  static String? keyProblem(String key) {
    if (key.startsWith('sb_secret_')) {
      return 'A secret key was supplied; only the publishable key may be used in the app.';
    }
    final parts = key.split('.');
    if (parts.length == 3) {
      try {
        final payload = utf8.decode(
          base64Url.decode(base64Url.normalize(parts[1])),
        );
        final claims = jsonDecode(payload);
        if (claims is Map && claims['role'] == 'service_role') {
          return 'A service_role key was supplied; refusing to start.';
        }
      } on FormatException {
        // Not a decodable JWT: treat as an opaque publishable key.
      }
    }
    return null;
  }
}
