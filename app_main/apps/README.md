# mizan

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Google sign-in configuration

Android Google sign-in requires the Google OAuth **Web application client ID** to be supplied at build time and the matching Google provider to be enabled in Supabase Authentication. The client ID is public configuration; do not commit client secrets or service-account credentials.

Use the client ID from the same Google Cloud project configured in Supabase:

```bash
flutter build apk \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

The Android package registered in Google Cloud must match `com.example.mizan`, and the SHA-1/SHA-256 fingerprints for the debug or release keystore used to build the APK must be registered. Supabase Authentication must have Google enabled with the corresponding client ID and secret, and the mobile callback URL must include `io.supabase.mizan://login-callback`. The application now rejects a Google/Drive-only result unless a valid Supabase session is also created.
