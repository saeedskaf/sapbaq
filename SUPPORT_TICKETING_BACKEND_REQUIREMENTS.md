# Support / Ticketing — Backend Requirements (Customer App)

**Audience:** Backend developer
**Author:** Mobile team (Flutter)
**Status:** Proposal for review
**Goal:** Turn the support ticket thread into a chat-grade experience — unread badges,
push notifications when an agent replies, last-message previews, and sensible ordering —
**without over-engineering it**. Every change below is **additive and backward-compatible**;
the app keeps working with the current responses and progressively enhances as fields appear.

---

## 1. Current state (for reference)

The app already integrates these endpoints:

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/support/tickets/` | List the signed-in user's tickets (paginated) |
| `POST` | `/support/tickets/` | Create a ticket `{subject, body}` |
| `GET` | `/support/tickets/{id}/` | Ticket detail incl. the `messages[]` thread |
| `POST` | `/support/tickets/{id}/messages/` | Add a reply `{body}` (reopens a resolved ticket) |

Current shapes the app parses:

```jsonc
// Ticket (list item + detail)
{ "id": 12, "subject": "...", "status": "OPEN", "priority": "NORMAL",
  "created_at": "2026-06-29T10:00:00Z", "messages": [ /* detail only */ ] }

// TicketMessage
{ "id": 88, "body": "...", "sender": "Support", "is_mine": false,
  "created_at": "2026-06-29T10:05:00Z" }
```

- `status ∈ OPEN | IN_PROGRESS | RESOLVED | CLOSED`
- `priority ∈ LOW | NORMAL | HIGH | URGENT`

**The main gap:** once a customer leaves a ticket, there is no signal that an agent
replied — no unread count, no push, no inbox entry. The customer has to manually reopen
the thread to discover a response. Fixing that is the priority of this document.

---

## 2. Priorities

| Priority | Item | Why |
|---|---|---|
| **P0** | Unread tracking (§3) | Customers must see "you have a new reply" |
| **P0** | Push + inbox notifications on agent reply (§4) | The reason replies go unnoticed today |
| **P1** | List metadata: `last_message`, `last_activity_at`, ordering (§5) | Makes the list usable and chat-like |
| **P1** | `sender_type` + `can_reply` on the thread (§6) | Correct bubble rendering + disabling the composer |
| **P2** | Attachments (§7), ticket category (§8) | Nice-to-haves, ship when convenient |

P0 + P1 alone deliver an excellent, practical system. P2 is optional polish.

---

## 3. Unread tracking (P0)

"Unread for the customer" = messages authored by **staff/system** that arrived **after** the
customer last opened the ticket.

### 3.1 Per-ticket unread count
Add `unread_count` (integer) to **every ticket** in both the list and detail responses:

```jsonc
{ "id": 12, "subject": "...", "status": "IN_PROGRESS", "unread_count": 2, ... }
```

### 3.2 Marking a ticket read — dedicated endpoint (decided)

```
POST /support/tickets/{id}/read/   → 204 No Content
```

Sets `last_read_at = now()` for the customer and zeroes the ticket's `unread_count`. The app
calls it once after the thread is rendered.

**Why a dedicated endpoint rather than auto-marking on `GET`:** it keeps `GET` idempotent and
side-effect-free (safe to retry/prefetch), and it lets the app decide *when* "read" actually
happens (after the user sees the messages) instead of merely loading the screen. Must be
**idempotent** — calling it again on an already-read ticket is a no-op `204`.

### 3.3 Global unread badge
The app shows a badge on the "Support" entry point. Expose the total cheaply:

```
GET /support/tickets/unread-count/
→ 200 { "count": 3 }          // total tickets with unread_count > 0  (or total unread messages — see note)
```

`count` = **number of tickets that have at least one unread message** (this is what the badge
shows — a count of conversations with new replies, not a raw message total).

Alternatively, if you already return a global notifications/summary object on app start, you
may fold `support_unread` into it instead of a dedicated endpoint — your call.

---

## 4. Notifications on agent reply (P0)

When **staff** replies to a ticket (and on the status changes noted below), the backend
should both:

1. **Send an FCM push** to the customer's registered devices, and
2. **Create an inbox notification** (so it also appears in `GET /notifications/`).

This reuses the existing push + device-registry plumbing (FCM is already wired and the
device token is registered on login).

### 4.1 Notification types

| `notification_type` | Trigger | Deep-link target |
|---|---|---|
| `support.reply` | Staff posts a message on the ticket | The ticket thread |
| `support.status_changed` | Ticket status changes (e.g. → RESOLVED / CLOSED) | The ticket thread |

`support.status_changed` is optional/nice-to-have; `support.reply` is the important one.
Do **not** notify the customer about their own messages.

### 4.2 FCM `data` payload (required keys)

The app routes a tapped push by reading ids from the FCM `data` map (strings). Include:

```jsonc
{
  "notification_type": "support.reply",
  "ticket_id": "12",
  "ticket_subject": "Issue with my order",
  "message_preview": "Hello, we've checked your order and…"  // truncated, ~120 chars
}
```

### 4.3 Inbox notification (`GET /notifications/`)

The app lifts ids out of the inbox item's `data` object (same convention as `order_id`).
Please include `ticket_id` there too:

```jsonc
{
  "id": 901,
  "notification_type": "support.reply",
  "title": "New reply to your ticket",
  "body": "Issue with my order: Hello, we've checked…",
  "created_at": "2026-06-29T11:00:00Z",
  "data": { "ticket_id": 12 }
}
```

> **Mobile-side note (no backend action):** we will add a `support.*` case to the app's
> deep-link resolver so these notifications open the ticket thread. We only need
> `ticket_id` present in `data` (push) and `data` (inbox) as shown above.

### 4.4 Preferences — none (decided)
`support.*` notifications are **transactional and always sent** — there is **no** dedicated
support toggle in the notification preferences, and none is needed. Do not gate them behind a
preference category.

---

## 5. List metadata & ordering (P1)

To render the list like a chat inbox, add to each **list item**:

```jsonc
{
  "id": 12,
  "subject": "Issue with my order",
  "status": "IN_PROGRESS",
  "priority": "NORMAL",
  "unread_count": 2,
  "last_activity_at": "2026-06-29T11:00:00Z",   // created_at of the most recent message (or ticket)
  "last_message": {
    "body": "Hello, we've checked your order and…",  // may be truncated server-side
    "sender_type": "STAFF",                            // see §6
    "created_at": "2026-06-29T11:00:00Z"
  }
}
```

- **Default ordering:** `-last_activity_at` (most recently active ticket first).
- **Optional filters:** `?status=OPEN` and `?has_unread=true`. Not required for v1.
- Pagination: keep the standard `{count, next, previous, results}` envelope already in use.

---

## 6. Thread rendering: `sender_type` + `can_reply` (P1)

### 6.1 `sender_type` on each message
The app currently relies on `is_mine` (keep it) but a stable enum lets us render system
messages and label the agent. Add `sender_type` and an optional display name:

```jsonc
{
  "id": 88,
  "body": "…",
  "is_mine": false,                 // keep — still used
  "sender_type": "STAFF",           // CUSTOMER | STAFF | SYSTEM
  "sender_name": "Mohammed (Support)",  // optional, shown above staff bubbles
  "created_at": "2026-06-29T11:00:00Z"
}
```

`SYSTEM` covers automated lines like "Ticket reopened" / "Marked resolved", which we can
render as centered, muted notices.

### 6.2 `can_reply` on the ticket detail
So the app can **disable the composer** instead of letting a reply fail, return a boolean
on the detail response:

```jsonc
{ "id": 12, "status": "CLOSED", "can_reply": false, ... }
```

Rule (decided):
- `OPEN / IN_PROGRESS` → `can_reply: true`
- `RESOLVED` → `can_reply: true` **and a reply reopens the ticket** (already the behavior today)
- `CLOSED` → `can_reply: false` — the ticket is final; the customer opens a **new** ticket
  instead. A reply attempt on a closed ticket should return `409 Conflict` (or `403`) with a
  display-ready message, so even if the app is stale the failure is graceful.

When `can_reply` is absent the app assumes `true` (backward compatible).

---

## 7. Attachments (P2 — optional)

Very common in support: let the customer attach a screenshot.

- `POST /support/tickets/{id}/messages/` accepts **multipart** with an optional `image` file
  alongside `body` (body may be empty when an image is sent).
- Each message returns:

```jsonc
{ "id": 88, "body": "", "attachments": [ { "url": "https://…/a.jpg", "type": "image" } ], ... }
```

Limit to images for v1 (jpg/png, e.g. ≤ 5 MB). Skip if not trivial.

---

## 8. Ticket category (P2 — optional)

Optional, to help agents triage on create:

- Optional `category` on `POST /support/tickets/`: e.g. `ORDER | PAYMENT | DELIVERY | ACCOUNT
  | OTHER`. The category list can be hard-coded in the app — no extra endpoint needed unless
  you'd prefer to own it server-side.

Additive; skip if not worthwhile.

> **Out of scope (decided):** linking a ticket to a specific order, and message-thread
> pagination. The full `messages[]` thread is returned on the detail response as today.

---

## 9. Summary of new fields (all backward-compatible)

| Object | New field | Type | Priority |
|---|---|---|---|
| Ticket (list + detail) | `unread_count` | int | P0 |
| Ticket (list) | `last_activity_at` | ISO datetime | P1 |
| Ticket (list) | `last_message` | `{body, sender_type, created_at}` | P1 |
| Ticket (detail) | `can_reply` | bool | P1 |
| TicketMessage | `sender_type` | `CUSTOMER\|STAFF\|SYSTEM` | P1 |
| TicketMessage | `sender_name` | string (optional) | P1 |
| TicketMessage | `attachments` | array | P2 |
| Ticket | `category` | enum | P2 |

## 10. New / changed endpoints

| Method | Path | Priority | Notes |
|---|---|---|---|
| `POST` | `/support/tickets/{id}/read/` | P0 | Mark read → `204`; idempotent. `GET` stays read-only |
| `GET` | `/support/tickets/unread-count/` | P0 | Global badge `{count}` = tickets with unread |
| `GET` | `/support/tickets/` | P1 | Add metadata + order by `-last_activity_at`; optional `?status=`, `?has_unread=` |
| `POST` | `/support/tickets/{id}/messages/` | P2 | Accept optional multipart `image` |

## 11. Notification types (summary)

| `notification_type` | Channel | `data` keys | Priority |
|---|---|---|---|
| `support.reply` | Push + inbox | `ticket_id`, `ticket_subject`, `message_preview` | P0 |
| `support.status_changed` | Push + inbox | `ticket_id`, `status` | P2 |

---

## 12. Acceptance criteria

- [ ] An agent reply increments `unread_count` and triggers a `support.reply` push **and**
      an inbox notification carrying `ticket_id`.
- [ ] `POST /support/tickets/{id}/read/` zeroes `unread_count` and is idempotent.
- [ ] `GET /support/tickets/unread-count/` reflects the badge count accurately
      (tickets-with-unread).
- [ ] The ticket list is ordered by most recent activity and includes `last_message`.
- [ ] `sender_type` is correct for customer/staff/system messages.
- [ ] `can_reply` is `false` for `CLOSED`; a reply attempt on a closed ticket fails with a
      display-ready `409/403`.
- [ ] `support.*` notifications are always sent (no preference gate).
- [ ] All existing fields remain present; older app builds keep working unchanged.

---

## 13. Resolved decisions (no open questions)

These were discussed and are **final** — no need to come back on them:

1. **Read-marking:** dedicated `POST /support/tickets/{id}/read/` endpoint (not auto-on-GET).
2. **`unread-count` semantics:** number of tickets that have at least one unread message.
3. **Support notification preferences:** none — `support.*` is always-on transactional.
4. **`can_reply`:** `OPEN/IN_PROGRESS` → true; `RESOLVED` → true (reply reopens); `CLOSED` →
   false (open a new ticket).
5. **Out of scope:** ticket↔order linking and message-thread pagination.

Thanks! Happy to jump on a quick call if anything in the field shapes needs tightening.
