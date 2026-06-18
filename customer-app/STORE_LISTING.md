# Sapbaq — Store Listing & Brand Naming

Reference for the Play Store / App Store consoles (these can't be set from the
codebase). Goal: present the official brand **Sapbaq | ســـبّاقـــ** while making
the app discoverable to users who search the plain word **سباق**.

## App display name
- **Preferred:** `Sapbaq | ســـبّاقـــ`
- **Fallback** (if the store truncates it): `Sapbaq`
- **Native launcher label** (in the build): `Sapbaq` — Android `android:label`,
  iOS `CFBundleDisplayName`. The elongated wordmark `ســـبّاقـــ` is used
  **in‑app** (splash, login, menus, About, welcome strings).

## Search optimization — must rank for "سباق"
Include the plain, unstyled **سباق** (no diacritics, no tatweel) in the store
title/subtitle, the keyword field, and the description. Tatweel/diacritic forms
do **not** match plain-text search, which is why the searchable copy uses `سباق`.

### Apple App Store
- **Subtitle (≤30 chars):** `سباق · ماء للمساجد` (or EN: `Water delivery to mosques`)
- **Keywords (≤100 chars):** `سباق,Sapbaq,ماء,مسجد,مساجد,توصيل,صدقة,تبرع,water,mosque,Kuwait,donation,charity`

### Google Play
- **Short description:** lead with the brand + `سباق`, e.g.
  `Sapbaq (سباق): أهدِ مياه الشرب وتوصيلها إلى مساجد الكويت — صدقة جارية.`
- Naturally repeat `سباق`, `Sapbaq`, `مساجد`, `توصيل ماء`, `صدقة` in the full
  description (avoid keyword stuffing).

## Brand usage rules
- **In-app wordmark / marketing:** `ســـبّاقـــ` (elongated, with tatweel).
- **Latin brand:** `Sapbaq`.
- **Searchable / machine-readable text:** plain `سباق`.
- English UI uses `Sapbaq`; Arabic UI uses `ســـبّاقـــ`.

## Localized listings
Provide both an **Arabic** and an **English** store listing (the app now ships
full ar + en). Use the matching brand form in each.
