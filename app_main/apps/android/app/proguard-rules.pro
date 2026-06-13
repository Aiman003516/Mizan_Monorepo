# Flutter/Dart ProGuard Rules for Release Builds

# --- Flutter Engine ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.** { *; }

# --- Firebase ---
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# --- Google Sign-In ---
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# --- Drift (SQLite) ---
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# --- Local Auth (Biometrics) ---
-keep class androidx.biometric.** { *; }

# --- General ---
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

-dontwarn kotlin.**
-dontwarn kotlinx.**
-dontwarn javax.annotation.**
