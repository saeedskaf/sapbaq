# Sapbaq Customer App — Frontend Implementation Plan

> **Status:** In progress (started 2026-06-18)
> **Requirements source:** Manager email (theme · i18n · profile · branding · store naming) measured against `CUSTOMER_APP_FRONTEND_HANDOFF.md` (backend contracts — ✅ done & tested).
> **Scope:** `customer-app` only. The management app ("Sapbaq for Staff" / `admin-app`) is a separate, later effort.

---

## Locked decisions

1. **Brand-name text** — in-app wordmark is the manager's elongated form **`ســـبّاقـــ`** (consistent on splash, login, menus, notifications, and the `appName`/welcome strings). Store listing title: **`Sapbaq | ســـبّاقـــ`** (fall back to **`Sapbaq`** if truncated). Store **keywords/description/search use plain `سباق`** (no diacritics, no tatweel) for discoverability.
2. **Theming** — proper Material `ColorScheme`-driven **Light + Dark + Match-device**. Neutral/surface/text tokens resolve through the theme so they flip automatically (not the brightness-shim shortcut).
3. **Profile relocation** — moved out of the bottom dock to the **top corner of Home** (auto-positions by text direction); opens as a pushed full-screen route. Bottom nav drops to **4 tabs** (Home · Mosques · Media · Orders).
4. **Settings persistence** — `shared_preferences` behind a small `SettingsService` abstraction, loaded in `main()` before first frame (no theme/locale flash).
5. **Mosque filters (handoff §7)** — cascading governorate → area → block filters are **in scope**.

---

## Current-state baseline (what exists today)

| Area | Today | Action |
|---|---|---|
| Locale | Hardcoded `Locale('ar')`, always RTL (`app.dart`, `app_constants.dart`) | Locale switch + LTR |
| Theme | `AppTheme.light` only — **no dark** (`app_theme.dart`) | Add dark + `themeMode` |
| Translations | **Arabic only** — `app_ar.arb` (202 keys); no `app_en.arb` | Author full English ARB |
| Profile | 5th **bottom-nav tab** (`app_shell.dart`, `app_router.dart`) | Move to Home top corner |
| Profile contents | Identity (name+phone), FAQ/Contact/About/Privacy/Terms, Logout/Delete | Add the new sections below |
| `Accept-Language` | Hardcoded `'ar'` (`dio_client.dart`) | Dynamic from locale |
| Info pages | Static Arabic in code (`info_content.dart`) | Migrate to CMS `/content/{slug}/` |
| User model | No `email` (`user.dart`) | Add `email` |
| App name | `سَبّاق` (Android `android:label`, iOS `CFBundleDisplayName`) | Rebrand per §WS6 |
| Brand text | Only 3 strings (`appName`, `homeWelcome`, `guestWelcomeTitle`); wordmark is the logo image | Low surface area |

**Stack:** Flutter (Dart ^3.11) · `flutter_bloc` (Cubit) · `go_router` · `dio` · `flutter_secure_storage` · `google_maps_flutter` · gen-l10n · bundled Tajawal/Poppins. **Backend host:** `sapbaq.albairakgroup.com`.

---

## Workstreams

### WS0 — Settings foundation *(prerequisite for WS1 + WS2)*
Single source of truth for theme mode + locale, persisted, feeding `Accept-Language`.
- **New** `core/settings/settings_service.dart` (shared_preferences-backed), `core/settings/settings_cubit.dart`.
- **Edit** `main.dart` (load settings pre-`runApp`; pass current-lang notifier to Dio), `app.dart` (`BlocBuilder` → `theme`/`darkTheme`/`themeMode`/`locale`), `dio_client.dart` + `auth_interceptor.dart` (dynamic `Accept-Language`).

### WS1 — Theming (Light / Dark / System)  — *req. A.1*
- **Refactor** `app_theme.dart` into a shared builder + `light`/`dark`.
- **Edit** `colors_custom.dart` — dark palette; route surface/text/border through `ColorScheme`; audit ~40 widgets that reference `ColorsCustom.*` directly.
- Dark `statusBarStyle` variant.
- **New** `features/settings/.../appearance_screen.dart` — Light / Dark / System.

### WS2 — Localization (English + RTL/LTR)  — *req. A.2*
- **New** `lib/l10n/app_en.arb` — translate all 202 keys.
- Direction follows locale; audit explicit-direction files: `floating_nav_bar.dart`, `mosques_screen.dart`, `mosque_marker_icon.dart`, `custom_form_field.dart`, `custom_text.dart`; replace `left/right` paddings with `*Directional`; check icon mirroring + `intl_phone_field`.
- **New** `features/settings/.../language_screen.dart` — Arabic / English (instant; updates `Accept-Language` so bilingual API fields flip).

### WS3 — Navigation & Profile relocation  — *req. A.3 (nav)*
- **Edit** `app_router.dart` — remove Profile shell branch; add pushed `/profile`.
- **Edit** `app_shell.dart` — 4 nav items (`FloatingNavBar` already dynamic + RTL-aware).
- **New** reusable profile-avatar button in `home_screen.dart`'s `_HomeHeader` (beside the bell; auto-positions by direction).

### WS4 — Profile sections (data-driven)  — *req. A.3*
| Item | Screen(s) | Endpoint | Notes |
|---|---|---|---|
| Personal info + Email + Mobile | extend `profile_screen.dart` | `GET/PATCH /auth/me/` | add `email` to `user.dart`; phone read-only |
| Saved Addresses | `features/addresses/…` | `/addresses/` CRUD | `area` required; `is_default`; optional map pin |
| Favorite mosques | favorites screen + heart on `mosque_card.dart` | `GET/POST/DELETE /mosques/favorites/` | idempotent |
| Notification prefs | prefs screen | `GET/PATCH /notifications/preferences/` | 4 toggles |
| Privacy/Terms/About/FAQ | refactor `info_screens.dart` → CMS | `GET /content/{slug}/` | FAQ = accordion from `sections`; bilingual |
| Contact Support | `features/support/…` | `/support/tickets/` (+ `/messages/`) | chat via `is_mine`; reply reopens |
| Logout / Delete | exists ✅ | `DELETE /auth/me/` | done |

- **Edit** `api_endpoints.dart` — add addresses, favorites, notification preferences, content(slug), support tickets, mosques filters.
- Profile order: Personal info → Addresses → Favorites → Language → Appearance → Notifications → Privacy → Terms → Contact Support → Logout → Delete.

### WS5 — Brand-name consistency  — *req. A.4*
- Splash/login/menu use the logo lockup (on_light vs on_dark per theme).
- Brand text token = `ســـبّاقـــ` (the 3 strings + any new brand surfaces).

### WS6 — App store naming & SEO  — *req. A.5*
- Android `android:label`, iOS `CFBundleDisplayName` → per locked decision #1.
- Store consoles (out-of-repo): title `Sapbaq | سباق`/`Sapbaq`; keywords/description include plain `سباق`.

### WS7 — Mosque governorate/area/block filters  — *handoff §7*
- Cascading filters in `mosques_screen.dart` via `GET /mosques/filters/` (+ `/mosques/?governorate=&area=&block=`).

### WS8 — Orders verify  — *handoff §9*
- Keep per-card `created_at` timestamp + full history; do **not** add staff-only counters.

---

## Sequencing
1. **Phase 1 — Foundation:** WS0 → WS1 → WS2.
2. **Phase 2 — Navigation:** WS3.
3. **Phase 3 — Profile data:** WS4 (email → addresses → favorites → notif prefs → CMS → support).
4. **Phase 4 — Brand & store:** WS5 + WS6.
5. **Phase 5 — Bonuses + QA:** WS7, WS8, full light/dark + RTL/LTR pass.

---

## Progress checklist
- [x] WS0 Settings foundation — `SettingsService` (shared_preferences) + `SettingsCubit` + `LocaleInterceptor`; `main.dart`/`app.dart`/Dio wired; analyze+tests green
- [x] WS1 Theming (engine) — `ThemeColors` ThemeExtension + brightness-parameterized `AppTheme`; **33 files / 340 call sites** migrated to `context.colors`; brand-fixed colors preserved (68 refs); analyze + tests green. *(Appearance toggle screen + default light→system moved to WS3/QA.)*
- [x] WS2 Localization — full **`app_en.arb` (202 keys)** + ICU plural; `en` in supportedLocales; direction follows locale (audited — fixed 1 `TextAlign.right`→`start`, rest already directional); **en/LTR widget test** added. *(Language toggle screen moved to WS3.)*
- [x] WS3 Navigation + settings — Profile relocated to **Home top-corner avatar** (pushed route); bottom nav → **4 tabs**; **Appearance** (Light/Dark/System) + **Language** (ar/en) screens wired to `SettingsCubit`; Profile gained a localized **Settings** section (+ fixed hardcoded Arabic section labels). *(Flip theme default light→system happens in QA after a visual pass.)*
- [x] WS4 Profile sections — **all 6 slices done.** email/personal-info edit; notification preferences (optimistic toggles); saved addresses (`/addresses/` CRUD); favorite mosques (app-wide `FavoritesCubit` + heart on cards + favorites screen); CMS legal pages (About/Privacy/Terms/FAQ → `/content/{slug}/`, bilingual, FAQ accordion); **support tickets** (`/support/tickets/` — ticket list, chat thread aligned by `is_mine`, new-ticket form, reply reopens resolved). Profile reorganized per the manager's order: Account (addresses, favorites) → Settings (language, appearance, notifications) → Help (FAQ, contact, about, privacy, terms, support). Cleanup: removed dead static blobs from `info_content.dart`, localized `contactIntro`. All localized ar+en; analyze + tests green.
- [x] WS5 Branding — in-app brand text → `ســـبّاقـــ` (Arabic `appName`/`homeWelcome`/`guestWelcomeTitle`; en stays `Sapbaq`); OS title now locale-aware (`onGenerateTitle`); splash/login already use the logo image (made the auth logo brightness-aware). Test updated to expect the wordmark.
- [x] WS6 Store naming/SEO — native labels (`android:label`, iOS `CFBundleDisplayName`) → `Sapbaq`; store-console naming + `سباق` SEO documented in `customer-app/STORE_LISTING.md`.
- [x] WS7 Mosque filters — cascading governorate→area→block filter sheet (`/mosques/filters/`) + filter button beside search; list reloads with filters; paginates. Localized ar+en.
- [x] WS8 Orders — timestamp + no staff counters verified; **fixed** history limit (orders now paginate the full history). Theme default flipped light→**system**.
- [~] Final QA: analyze clean + tests green + full **release-grade APK build**; visual sweep (every screen × light/dark × ar-RTL/en-LTR) to be spot-checked in the APK on device.
