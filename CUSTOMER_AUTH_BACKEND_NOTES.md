# Customer App — Auth Implementation Notes for Backend

**Scope:** Customer app only (staff/admin app unchanged).
**Reference:** `Sapbaq_AUTH_Flow.pdf` (CEO-approved) + `FLUTTER_CUSTOMER_AUTH.md` (backend API spec).
**Status:** Flutter side implemented against the spec; `flutter analyze` clean, unit tests pass. Not yet device-run.

This document lists exactly what the app now sends/expects, the points where we need the
backend to confirm behaviour, and three product/security refinements we recommend adding
on the backend. Everything below is under `/api/v1/auth/`.

---

## 1. What the app now does (client contract)

The app implements the full **phone-OTP → 4-digit passcode → device-trust + local biometric**
flow. Google/Apple remain as alternative entry points. Guest browsing until purchase is unchanged.

### Endpoints the app calls

| Endpoint | Method | Auth | Request body (JSON) | App expects back |
|---|---|---|---|---|
| `otp/check-number/` | POST | public | `{ phone }` | `{ registered: bool, passcode_set: bool }` |
| `otp/request/` | POST | public | `{ phone }` | 200 (OTP sent) |
| `otp/verify/` | POST | public | `{ phone, code, device_id, device_name }` | session `{ access, refresh, user, is_new, needs_profile }` |
| `passcode/login/` | POST | public | `{ phone, passcode, device_id }` | session, or **428 / 423 / 400** (see §2) |
| `passcode/set/` | POST | Bearer | `{ passcode, passcode_confirm }` | `user` |
| `passcode/forgot/request/` | POST | public | `{ phone }` | 200 (OTP sent) |
| `passcode/forgot/reset/` | POST | public | `{ phone, code, new_passcode, new_passcode_confirm, device_id }` | session |
| `device/trust/request/` | POST | public | `{ phone }` | 200 (OTP sent) |
| `device/trust/verify/` | POST | public | `{ phone, code, device_id, device_name }` | `{ trusted: true }` (no session) |
| `social/google/` · `social/apple/` | POST | public | token (+ optional name) | session |
| `phone/request/` | POST | Bearer | `{ phone }` | 200 |
| `phone/verify/` | POST | Bearer | `{ phone, code, device_id, device_name }` | `user` (now with verified phone) |
| `profile/complete/` | POST | Bearer | `{ first_name, last_name, middle_name?, email }` | `user` |
| `refresh/` | POST | public | `{ refresh }` | `{ access, refresh? }` |
| `me/` | GET | Bearer | — | `user` |

### `user` object fields the app reads

```json
{ "id", "phone", "first_name", "middle_name", "last_name", "full_name",
  "email", "email_verified", "profile_completed", "passcode_set", "user_type" }
```

- **`passcode_set` is required** — it drives the "set your passcode" onboarding step and the
  returning-user routing. It must be present on the session `user` and on `GET /me/`.

### `device_id`

- The app generates a **UUID v4 once per install** and stores it in the iOS Keychain /
  Android Keystore (via `flutter_secure_storage`). It is **opaque** — please bind device trust
  to this exact string and don't parse it.
- It **survives logout** (so a logged-out-then-back-in user on the same device is still trusted
  and doesn't need a fresh OTP). It only changes on reinstall / storage wipe.
- `device_name` is a best-effort human label (e.g. "iPhone 14", "Pixel 8") for a trusted-device
  list; never use it for security.

### Local biometric

- Face ID / Touch ID is **entirely client-side** (via `local_auth`). The server is not involved.
  It only unlocks the session already stored on the device; the passcode remains the fallback.
  No endpoint needed.

---

## 2. Hard dependencies — please confirm these exactly

These are the points the client logic branches on. If any differ, the flow breaks.

1. **`passcode/login/` failure statuses (critical).** The app branches on the **HTTP status code**:
   - **428** → device untrusted → app runs the device-trust OTP flow, then retries login.
   - **423** → passcode locked (after 5 wrong tries) → app runs forgot-passcode.
   - **400** (or any other 4xx) → wrong passcode, still has attempts → app shows "wrong passcode" and lets the user retry.
   Please confirm these are returned as real HTTP statuses (not 200-with-error-body).

2. **`otp/check-number/`** returns `{ registered, passcode_set }`, sends **no OTP**, and returns
   `registered: false` for staff accounts (no enumeration of staff).

3. **Session shape** is `{ access, refresh, user, is_new, needs_profile }` for every sign-in
   endpoint (otp/verify, passcode/login, forgot/reset, social/*). `user.passcode_set` included.

4. **`device/trust/verify/` issues NO session** — just `{ trusted: true }`. The app then re-calls
   `passcode/login/`. (Matches the spec; just confirming.)

5. **`refresh/`** may rotate the refresh token; the app saves whichever `refresh` comes back (falls
   back to the old one if none is returned). Session is expected to last **90 days by inactivity**.

6. **Error body shape.** For messages we surface, the app reads `error.message` if present, else
   falls back to a status-based localized string. If your auth errors are plain DRF
   (`{ "detail": ... }` / `{ "field": [...] }`), the specific 428/423 flows still work (we branch
   on status), but the *text* shown for a generic 400 will be a generic localized message. If you
   want a specific server message shown, wrap it as `{ "error": { "code", "message" } }` or
   include a top-level `detail`.

7. **Google/Apple token audience** (unchanged from before): the app sends the Google `id_token`
   minted with `serverClientId`; Apple sends `identity_token` + raw `nonce`. Backend must trust the
   platform client IDs / verify the nonce as already agreed.

---

## 3. Recommended backend additions (from our review)

These were reviewed and agreed on our side; they need backend/product work to complete.

### 3.1 Weak-passcode rejection (server-side)
The app already rejects trivial codes up front (all-same like `0000`, and consecutive runs like
`1234` / `4321`). Please **also enforce this server-side** on `passcode/set/` and
`passcode/forgot/reset/` so the policy holds regardless of client. Suggested minimum: reject
all-identical and 4-length ascending/descending sequences. If the server rejects, return a 400
with a clear message.

### 3.2 Trusted-device management (new endpoints — not yet built client-side)
For security and privacy (GDPR "your devices"), we'd like users to see and revoke trusted devices,
and to remotely sign out a lost device. Proposed contract:

| Endpoint | Method | Auth | Returns |
|---|---|---|---|
| `device/trusted/` | GET | Bearer | `[{ id, device_name, last_used_at, current: bool }]` |
| `device/trusted/{id}/` | DELETE | Bearer | 204 (revokes trust; that device then needs a fresh OTP) |

The app already has the UI shell for a device list (previously used for passkeys) that we can
repurpose once these exist. Not blocking the main flow.

### 3.3 OTP recovery policy — reconsider the hard cap (product decision)
The current spec is: max **3 OTP sends per cycle**, then the number is blocked and the customer must
**email support to have staff reset the counter** (§8/§12). This controls Twilio cost but is unusually
harsh — a user who forgets their passcode *and* exhausts OTP is fully locked out pending a manual
human action.

Recommendation: keep a daily cap for cost, but replace the hard human wall with **exponential
backoff** (e.g. wait 15 min after the 3rd send, then 1 hour), so recovery is self-service. This
lowers support load and abandonment while still bounding cost. The app already shows the
"contact support" message when the backend returns the blocked state, so either policy works
client-side — this is a backend/product call.

---

## 4. Open questions

1. Confirm the exact status codes in §2.1 (428 / 423 / 400).
2. Confirm `passcode/set/` accepts `passcode_confirm` (the app sends it); is it required or optional?
3. Confirm `passcode_set` is present on both the session `user` and `GET /me/`.
4. Is there a minimum server-side account-lockout backoff on `passcode/login/` beyond the 5-try lock?
5. For §3.2, are you able to expose trusted-device list/revoke? If yes, we'll build the UI.
6. For §3.3, which OTP-recovery policy do you want to ship (hard cap vs backoff)?

---

*Prepared by the Flutter side. Nothing here changes the staff/admin app.*
