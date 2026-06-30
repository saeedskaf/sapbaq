# Production Readiness Audit — Sapbaq

_Audit date: 2026-06-29 · Scope: customer-app + admin-app · Method: code review + `flutter analyze` (not device-run)._

Both apps pass `flutter analyze` with **no issues**. Below is what remains before a final
production release, grouped by severity. Payment is listed but already known.

---

## 🔴 Blockers (must fix before publishing)

### 1. Android release signing uses **debug** keys (both apps)
`android/app/build.gradle.kts` → release build is signed with the debug keystore:
```kotlin
release {
    // TODO: Add your own signing config for the release build.
    signingConfig = signingConfigs.getByName("debug")
}
```
Google Play rejects debug-signed builds. **Action:** create a release keystore (`.jks`),
add `key.properties`, and wire a proper `signingConfigs.release`. Do this for **both**
`customer-app` and `admin-app`. (Owner-only — needs your keystore + credentials.)

### 2. CMS legal/info pages have no content
Privacy / Terms / About / FAQ are CMS-driven (`GET /content/{slug}/`). With no content the
app shows an error screen.
- **Privacy & Terms:** content drafted in `content/privacy-policy.md` and
  `content/terms-and-conditions.md` (Arabic + English) — paste into the CMS under slugs
  `privacy` and `terms`. Have them reviewed by legal counsel first.
- **About (`about`) & FAQ (`faq`):** drafted in `content/about-and-faq.md` (Arabic +
  English) — paste into the CMS under slugs `about` and `faq` (review/adjust copy first).

### 3. Payment is a mock flow _(known)_
`PaymentRepository.payOrder` does initiate→confirm against a mock endpoint. Needs a real
payment gateway + webhook on the backend, then the app wired to it. (Out of scope here.)

---

## 🟠 Important (should address before/at launch)

### 4. Restrict the Google Maps API key
The key is injected via `MAPS_API_KEY` (good — not committed), but it must be **restricted**
in Google Cloud Console to the apps' bundle IDs + Android SHA-1 / iOS bundle, and limited to
the Maps SDKs in use. Otherwise the key can be abused if extracted. _(Noted as pending in
project memory.)_

### 5. No crash/error monitoring
There is no Crashlytics/Sentry. Strongly recommended to catch field crashes after launch.
Firebase is already integrated, so **Firebase Crashlytics** is the natural choice. Note it
requires native Gradle plugin changes (Android) + `main()` error-handler wiring, which need a
real build to verify — best done in a session where a device/CI build can confirm it, rather
than analyze-only. Ready to do it when you can run a build.

### 6. Support contacts — ✅ confirmed
Live contact details now come from the backend (`GET /content/contact/`): phone/WhatsApp
`+96562224195`, email `info@albairakgroup.com`. The app's built-in fallback was aligned to
match.

---

## 🟡 Minor / polish

### 7. App version — ✅ DONE
The About screen now reads the version from the platform via `package_info_plus`
(`PackageInfo.fromPlatform()`), falling back to the bundled constant. No longer hardcoded.

### 8. Dead code — ✅ DONE
`coming_soon_screen.dart` (`ComingSoonScreen`) removed from both apps.

---

## ✅ Verified OK
- `flutter analyze` clean in both apps.
- **FCM** fully configured both platforms (iOS APNs done); push token registered on login.
- **OTP** is production (real SMS); dev-code scaffolding removed; `devMode` defaults false.
- **iOS permissions:** the customer app does **not** access device location, camera, or
  photos, so no `*UsageDescription` strings are required; `UIBackgroundModes` is set for push.
- **Base URL** points to production (`https://sapbaq.albairakgroup.com/api/v1`).
- **Localization:** Arabic/English in sync (no untranslated-message warnings from gen-l10n).
- Loading / error / empty states are handled across screens.

---

## Suggested order of work
1. Release keystores + signing (both apps). _(you)_
2. Enter CMS content: privacy, terms, about, faq. _(content/backend)_
3. Restrict the Maps key. _(you / cloud console)_
4. Add Crashlytics. _(small code change — can do on request)_
5. Real payment gateway. _(backend, then app wiring)_
6. Optional polish: dynamic version, remove dead code.
