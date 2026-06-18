# Sapbaq

Sapbaq is a charity platform in Kuwait for donating bottled drinking water and
having it delivered to mosques — an ongoing charity. This repository holds the
two Flutter mobile apps that make up the platform.

| App | Folder | Audience |
| --- | --- | --- |
| **Customer app** | [`customer-app/`](customer-app/) | The public: browse and donate water & gifts, pick a destination mosque, pay, and track delivery. Arabic + English (RTL/LTR), light/dark themes. |
| **Staff app** | [`admin-app/`](admin-app/) | Internal operations for staff and drivers. |

Both apps target **Android and iOS only**.

## Tech stack

Flutter (Dart) · `flutter_bloc` (Cubit) · `go_router` · `dio` · Google Maps ·
`gen-l10n` (Arabic + English) · bundled Tajawal/Poppins fonts.
