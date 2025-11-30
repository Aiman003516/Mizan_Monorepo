/// Access to compile-time environment variables.
/// These are "baked in" to the binary during build using --dart-define.
class EnvConfig {
  // --- Environment Selector ---
  // Defaults to 'dev' for safety. You must explicitly set 'prod' to touch real data.
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static bool get isProd => appEnv == 'prod';

  // --- API Configuration ---
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.mizan.com',
  );

  static const bool enableBetaFeatures = bool.fromEnvironment(
    'ENABLE_BETA',
    defaultValue: false,
  );

  // --- Third-Party Keys (Sensitive) ---
  // These return empty strings if not provided during build.
  static const String stripePublishableKey = String.fromEnvironment('STRIPE_KEY');

  static const String googleWindowsClientId = String.fromEnvironment('GOOGLE_WINDOWS_CLIENT_ID');

  static const String googleWindowsClientSecret = String.fromEnvironment('GOOGLE_WINDOWS_CLIENT_SECRET');

  // --- Helper Checks ---
  static bool get hasStripeKey => stripePublishableKey.isNotEmpty;
  static bool get hasGoogleKeys => googleWindowsClientId.isNotEmpty && googleWindowsClientSecret.isNotEmpty;
}