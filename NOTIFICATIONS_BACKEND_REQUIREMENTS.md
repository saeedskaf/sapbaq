# Push Notifications — Backend Requirements & Contract

**Audience:** backend developer
**Scope:** both apps — **Customer** (`com.albairakgroup.sapbaq`) and **Staff/Driver** (`com.albairakgroup.sapbaq.admin`)
**App-side status (2026-07-10):** everything below is already implemented, built, and verified in both apps (FCM wiring, Android notification channel with custom sound, iOS sound file bundled in both Xcode targets, deep links, token lifecycle). The only missing piece is the server-side configuration described here.

---

## 1) TL;DR — what we need from you

Set these in the server `.env` and restart:

```env
FCM_ANDROID_CHANNEL_ID=sapbaq_alerts_v1
FCM_ANDROID_SOUND=notify
FCM_IOS_SOUND=notify.caf
```

One unified sound for all notification types (no per-type control for now).

And two hard rules when sending:

1. **iOS makes no sound unless the APNs payload contains `aps.sound`.** Nothing on the app side can compensate — if you omit it, every iPhone push arrives silent. Always send `"sound": "notify.caf"` in `aps` for user-visible pushes.
2. **Every user-visible push must include a `notification` block (`title` + `body`).** Background/terminated display on both platforms depends on it. Data-only messages are rendered only while the app is in the foreground (we fall back to `data.title` / `data.body`); in background/killed they display nothing.

---

## 2) Sound & Android channel contract

| Item | Value | Notes |
|---|---|---|
| Android channel id | `sapbaq_alerts_v1` | Created by the app at startup, high importance (heads-up), custom sound attached. |
| Android sound resource | `notify` | Bundled at `res/raw/notify.wav` in both apps. Referenced **without** extension. |
| iOS sound file | `notify.caf` | Bundled in both app targets. Referenced **with** extension. 0.55 s, well under Apple's 30 s limit. |
| Legacy channel | `sapbaq_default` | Retired — the updated app deletes it on first run. Do not target it. |

**Why the channel id is versioned (`_v1`):** Android freezes a channel's sound/importance at creation time and silently ignores later edits. If we ever change the tone's character or importance, the app will ship a `sapbaq_alerts_v2` channel and we'll ask you to update `FCM_ANDROID_CHANNEL_ID`. (Swapping the audio bytes under the same filename doesn't require a version bump.)

**Android version behavior:**
- **Android 8+ (effectively all devices):** the *channel* decides the sound. `FCM_ANDROID_CHANNEL_ID` is the field that matters; the per-message `sound` value is ignored.
- **Android < 8:** the per-message `sound` (`notify`) applies. That's the only reason `FCM_ANDROID_SOUND` exists.

---

## 3) Required FCM payload shape

We use FCM data keys for deep-linking and the `notification` block for display. Reference message (FCM HTTP v1):

```json
{
  "message": {
    "token": "<device fcm token>",
    "notification": {
      "title": "تم توصيل طلبك",
      "body": "تم تسليم الطلب ORD-00042 بنجاح."
    },
    "data": {
      "notification_type": "order.delivered",
      "order_id": "42"
    },
    "android": {
      "priority": "HIGH",
      "notification": {
        "channel_id": "sapbaq_alerts_v1",
        "sound": "notify"
      }
    },
    "apns": {
      "headers": {
        "apns-priority": "10",
        "apns-push-type": "alert"
      },
      "payload": {
        "aps": {
          "sound": "notify.caf"
        }
      }
    }
  }
}
```

Rules:

- **`data` values must all be strings** (FCM requirement). The apps parse numeric ids tolerantly (`"42"` → 42).
- `notification.title` / `notification.body` — required for anything the user should see (Arabic text is fine; the apps render long bodies expandable on Android).
- `android.notification.channel_id` — send it explicitly. (New installs would also fall back to it via the manifest default, but explicit is deterministic.)
- `apns-priority: 10` + `apns-push-type: alert` — without these iOS may delay or drop alerts.
- **Do not send `aps.badge` for now.** The apps don't manage badge counts yet, so any badge you set would stick forever on the app icon. If you're already sending it, please stop until we add badge handling.

---

## 4) Deep-link `data` contract

Both apps read `notification_type` (falling back to `type`) plus the id fields below. A tapped notification navigates according to these rules — **evaluated in the listed order, first match wins.**

### Customer app

| Priority | Condition | Opens |
|---|---|---|
| 1 | `ticket_id` present | That support ticket's chat |
| 2 | `notification_type` starts with `support.` | Support (tickets list) |
| 3 | `order_id` present | That order's detail screen |
| 4 | anything else | Notifications inbox |

### Staff/Driver app

| Priority | Condition | Opens |
|---|---|---|
| 1 | `notification_type` starts with `pending_approval` **or** `approval_id` present | Approvals screen |
| 2 | `notification_type` starts with `escalation` **or** `escalation_id` present | Escalations screen |
| 3 | `order_id` present | Admin order detail |
| 4 | `destination_id` present | Driver destination detail |
| 5 | `notification_type` is `admin.order_created` or `admin.workshop_rejected` | Admin orders list |
| 6 | anything else | No navigation (notification still displays) |

So: **always include the most specific id you have** (`order_id`, `ticket_id`, `destination_id`, …) alongside `notification_type`.

---

## 5) Device registry — what the apps already do

You already have these endpoints; documenting the exact client behavior so server-side assumptions match:

- **On login (and whenever FCM rotates the token):** `POST /notifications/devices/` with body `{"token": "<fcm token>", "platform": "ios" | "android"}`. The same token may be re-POSTed (e.g. after reinstall or token refresh) — treat it as an upsert.
- **On logout:** `DELETE /notifications/devices/{token}/`, and the app deletes its local FCM token, so the next login registers a fresh one.
- **Server-side hygiene:** when FCM responds `UNREGISTERED` / `NOT_FOUND` for a token, prune it from the registry (we understood this is already in place).

Token registration is resilient on the app side (iOS APNs cold-start race was fixed 2026-07-10), so once a user logs in with the updated build, their device *will* appear in the registry.

---

## 6) Rollout ordering (one-time note)

The `sapbaq_alerts_v1` channel only exists on devices that have **run the updated app build at least once**. If you flip `FCM_ANDROID_CHANNEL_ID` while users are still on the old build, their notifications fall back to a default/fallback channel — they still arrive, but with the default sound and lower priority.

Recommended order:
1. Updated app builds get distributed/installed.
2. Then set the `.env` values and restart.

(Not fatal if reversed — just degraded sound/priority on not-yet-updated installs.)

---

## 7) Joint test checklist (after `.env` is live)

Per platform (one Android device + one iPhone, per app):

- [ ] **Foreground:** push arrives → banner shows → **custom tone audible** → tap navigates to the right screen.
- [ ] **Background:** same, from the system tray.
- [ ] **Terminated (swiped away):** same — tap must cold-start the app and still land on the right screen.
- [ ] **Deep-link matrix:** one push per type in §4's tables (order, ticket/support, approval, escalation, destination).
- [ ] **Logout:** after logging out, the device must receive nothing.
- [ ] Long Arabic body (2–3 lines) renders expandable on Android.

Quick sanity check without backend code: Firebase Console → Messaging → *Send test message* to a device token; under **Additional options** set Android channel `sapbaq_alerts_v1` and iOS sound `notify.caf`.

---

## 8) FAQ

**Do we need the audio files on the server?**
No. The payload carries only *string names* (`sapbaq_alerts_v1`, `notify`, `notify.caf`); both operating systems resolve the actual audio from files **bundled inside the app packages**, which are already in place. There is nothing to upload, host, or serve.

**Can we get different sounds per notification type later?**
Yes — that's an app+backend change together: the app ships one channel per type (`sapbaq_orders_v1`, `sapbaq_alerts_v1`, …) and you route `channel_id`/`aps.sound` by type. Ask us first; don't invent channel ids server-side, they must exist in the app.

**What happens if we send a `channel_id` the app never created?**
Android shows the notification on a fallback channel (default sound, default importance). Never invent ids.

**Do you handle silent/data-only pushes (`content-available`)?**
Not currently — there is no background data processing. Anything meant for the user needs the `notification` block; anything without it is only useful while the app is open (foreground refresh already works: the apps re-sync unread state on every foreground push).

**Message ids / duplicates:** the apps dedupe foreground notifications by FCM `message_id`, so a redelivered message updates in place rather than stacking.
