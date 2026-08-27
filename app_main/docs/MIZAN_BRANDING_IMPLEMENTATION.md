# Mizan Branding Implementation

## Selected identity

Mizan branding now uses the selected concept 8 direction: a balanced two-pan scale, a turquoise arch, connected relationship nodes, and an open accounting ledger. The mark is intended to communicate **balance, measurement, accounting records, and CRM relationships** rather than a generic fintech symbol.

## Shared assets

The selected transparent PNG is installed under the existing asset names so current in-app references remain compatible:

```text
app_main/apps/assets/images/mizan_full.png
app_main/apps/assets/images/mizan.png
```

Both assets are 1024 × 1024 PNG files with an alpha channel. The existing login and onboarding screens reference `assets/images/mizan_full.png`, so they now display the selected identity without requiring separate screen-specific code.

## Android startup and launcher

Android startup uses:

```text
app_main/apps/android/app/src/main/res/drawable/splash_logo.png
app_main/apps/android/app/src/main/res/values/colors.xml
```

The splash background is the Mizan midnight-navy color `#071B33`. Android and Windows launcher resources were regenerated from `assets/images/mizan_full.png` using the existing `flutter_launcher_icons` configuration.

## Drawer and company image setting

The existing Company Profile screen in Settings provides the image picker. A selected image is copied into the app’s private documents image directory and its path is stored through `PreferencesRepository` under `company_image_path`. The `CompanyProfileController` updates its Riverpod state after saving, so the dashboard drawer refreshes immediately when the profile screen is closed.

The dashboard drawer behavior is:

1. If the user has selected a company/user image, the drawer displays that private image.
2. If no custom image is configured, the drawer displays the selected Mizan logo.
3. The company name and user name continue to come from the existing company-profile state.
4. Cloud online/offline status remains separate from the image and is not changed by this branding work.

The current image setting is **device-local**. It is suitable for guest/local workflows and for personal or device branding. It is not yet an organization-wide cloud branding record synchronized to every employee device. Adding organization-wide branding would require a separately authorized Supabase profile/settings contract, RLS policy, upload storage policy, and migration.

## Regenerating assets after a future logo change

Replace the shared asset while retaining the existing filename, then run from the Flutter application directory:

```powershell
cd D:\mizan_monorepo\app_main\apps
flutter pub get
dart run flutter_launcher_icons
```

For a new Android build, clear stale native resources only when needed:

```powershell
flutter clean
Remove-Item -Recurse -Force .\android\app\.cxx -ErrorAction SilentlyContinue
flutter pub get
flutter build apk --debug --target-platform android-arm64
```

No accounting, CRM, authentication, RLS, audit, or local-AI authority is changed by the branding implementation. The image picker does not grant additional permissions or mutation authority.
