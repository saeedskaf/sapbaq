# Sapbaq — سَبّاق (Customer App)

A Flutter mobile app for **سَبّاق (Sapbaq)**, a charity platform in
Kuwait that lets people donate bottled drinking water and have it delivered to
mosques — an ongoing charity (ṣadaqah jāriyah) whose reward continues with every
worshipper who drinks. This is the **customer-facing app**: browse and donate
water and gifts, choose a destination mosque, pay, and track delivery.

The UI is **Arabic-first and fully right-to-left (RTL)**.

> **Portfolio note:** this is a real client project shared to showcase
> production Flutter architecture. The backend is private, so the app needs a
> running API to be fully functional, but the codebase, structure, and patterns
> are all here to read.

## Features

- **Authentication** — phone-based sign up / login, OTP verification, forgot &
  reset password, secure token storage with automatic refresh.
- **Catalog** — water products and charity gifts with categories, image/video
  galleries, and detail screens.
- **Mosques** — browse and search mosques, view them on a **Google Map** with
  custom markers, and pick a delivery destination.
- **Cart & checkout** — cart management, donation destinations, and payment.
- **Orders** — order history, live status tracking, delivery-proof media, and
  reviews.
- **Showcase, banners & notifications** — promotional content and an in-app
  notification feed.
- **Profile & info** — account management plus about/contact/help screens.

## Tech stack

| Area | Choice |
| --- | --- |
| Framework | Flutter (Dart SDK `^3.11`) |
| State management | `flutter_bloc` (Cubit) + `equatable` |
| Routing | `go_router` (with auth-guard refresh stream) |
| Networking | `dio` with auth/error interceptors |
| Secure storage | `flutter_secure_storage` (access/refresh tokens) |
| Maps | `google_maps_flutter` |
| Localization | Flutter `gen-l10n` (Arabic, RTL) |
| Fonts | `google_fonts` — bundled Tajawal (Arabic) + Poppins (Latin), offline |
| Media | `video_player` + `chewie` |

## Architecture

Feature-first, layered structure with a shared `core/`:

```
lib/
├── app/            # App widget, theme wiring, router (go_router) + routes
├── core/
│   ├── auth/       # Auth guard
│   ├── bloc/       # Shared load/form status helpers
│   ├── config/     # Environment (build-time config)
│   ├── constants/  # App constants & asset paths
│   ├── network/    # Dio client, endpoints, interceptors, session manager
│   ├── storage/    # Secure storage
│   ├── theme/      # Colors & theme
│   ├── utils/      # Validators, date/media helpers
│   └── widgets/    # Reusable UI (buttons, fields, dialogs, nav bar, …)
├── features/       # auth, home, products, mosques, cart, orders, gifts,
│                   #   showcase, banners, notifications, profile, info
│   └── <feature>/
│       ├── data/           # models + repository
│       └── presentation/   # screens, widgets, bloc/cubit
└── l10n/           # Arabic ARB + generated localizations
```

Each feature keeps its `data` (models, repositories) separate from its
`presentation` (screens, widgets, Cubits), so business logic stays testable and
UI stays thin.

## Getting started

### Prerequisites

- Flutter SDK (`^3.11`) and Dart
- An IDE with the Flutter plugin (or just the CLI)
- A **Google Maps API key** (Maps SDK for Android and/or iOS) if you want the
  map to render

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure the Google Maps key (build-time injection)

The key is **never committed** — it is injected at build time and the files that
hold it are gitignored. Provide your own:

**Android** — add a line to `android/local.properties` (gitignored):

```properties
MAPS_API_KEY=your_android_maps_api_key
```

(Alternatively, set a `MAPS_API_KEY` environment variable.)

**iOS** — copy the template and fill in your key:

```bash
cp ios/Flutter/Maps.xcconfig.example ios/Flutter/Maps.xcconfig
# then edit ios/Flutter/Maps.xcconfig and set MAPS_API_KEY
```

Without a key the app still builds and runs — only the map view stays blank.
Restrict your key by package name / bundle ID (`com.albairakgroup.saqia`) in the
Google Cloud Console.

### 3. Run

```bash
flutter run
```

The API base URL and dev-mode flag are configurable at build time:

```bash
flutter run \
  --dart-define=BASE_URL=https://your-api.example.com/api/v1 \
  --dart-define=DEV_MODE=false
```

### Tests

```bash
flutter test
```

## License

This repository is published publicly **for portfolio and evaluation purposes
only**. The code is free to read, but not licensed for reuse — see
[LICENSE](LICENSE). All rights reserved.
