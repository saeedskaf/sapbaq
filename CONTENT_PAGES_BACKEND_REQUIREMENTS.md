# Content & Info Pages — Backend Requirements (Customer App)

**Audience:** Backend developer
**Author:** Mobile team (Flutter)
**Goal:** Make the app's info/content pages — **Privacy Policy, Terms & Conditions, About,
FAQ, and Contact Us** — fully driven by the backend, so they can be edited and localized
without shipping a new app build. This document lists every endpoint, the exact JSON the app
parses, the localization rules, and the empty-state behavior.

The app sends `Accept-Language` on every request (`ar` or `en`); **all text fields below must
be returned already localized** for that language.

---

## 1. CMS content pages — `GET /content/{slug}/`

Already integrated in the app. These four slugs render long-form pages:

| Slug | Screen | How it renders |
|---|---|---|
| `privacy` | Profile → Privacy Policy | `body` paragraph, then optional titled `sections` |
| `terms` | Profile → Terms & Conditions | `body` paragraph, then optional titled `sections` |
| `about` | Profile → About | `body` (under a branded logo/version header) + optional `sections` |
| `faq` | Profile → FAQ | `sections` rendered as an **accordion**: each `title` = question, `body` = answer |

### Response shape (exact)
```jsonc
{
  "slug": "privacy",
  "title": "سياسة الخصوصية",        // localized; used as the screen content title
  "body":  "نص تمهيدي ...",          // localized; main paragraph (may be empty for FAQ)
  "sections": [                       // ordered sub-sections
    {
      "id": 1,
      "title": "المعلومات التي نجمعها", // section heading  (FAQ: the question)
      "body":  "نجمع الاسم ورقم ...",   // section paragraph (FAQ: the answer)
      "sort_order": 1
    }
    // ...
  ]
}
```

### Rules
- **`sort_order`** controls section order (ascending). The app re-sorts by it.
- **Privacy / Terms / About:** put the intro in `body`; each heading + paragraph is a
  `section` (`title` + `body`). `sections` may be empty if the whole page is one `body`.
- **FAQ:** leave `body` empty and put each **question/answer** as a `section`
  (`title` = question, `body` = answer). Order by `sort_order`.
- **Localization:** return `title` / `body` / section text in the requested `Accept-Language`
  (`ar` default, `en`). One slug, two languages.
- **Plain text** (no HTML/markdown rendering in the app). Use line breaks within `body` for
  paragraphs if needed.

### When a page isn't published
If a slug has no content yet, the app shows a **simple "coming soon" message** (no error). So
either return **404**, or **200 with empty `body` and empty `sections`** — both are treated as
"not available." Once you publish content, it appears automatically (no app update).

> Reference copy (Arabic + English) for all four pages is provided in the repo `content/`
> folder: `privacy-policy.md`, `terms-and-conditions.md`, `about-and-faq.md`. Privacy & Terms
> should get a legal review before publishing.

---

## 2. Contact Us — `GET /content/contact/`  (NEW — please add)

The "Contact us" screen now reads its details from the backend. This is **structured data**
(not a long-form page), so it's a separate, simple endpoint.

### Response shape (exact)
```jsonc
{
  "phone":         "+96562224195",       // tappable → dialer
  "whatsapp":      "+96562224195",       // tappable → wa.me (digits only are extracted)
  "email":         "info@albairakgroup.com", // tappable → mailto
  "address":       "الكويت - ...",        // OPTIONAL, localized; shown only if present
  "working_hours": "السبت - الخميس، 9ص - 5م" // OPTIONAL, localized; shown only if present
}
```

### Rules
- `phone`, `whatsapp`, `email` are the core fields and should always be present.
- `address` and `working_hours` are **optional and localized** (follow `Accept-Language`);
  the app renders them only when non-empty.
- Phone/WhatsApp in international format (`+965…`). The app strips non-digits for the wa.me
  link, so any human-readable spacing is fine.
- **Fallback:** the app ships with built-in defaults and uses them until this endpoint
  responds (and if it's missing). So adding this endpoint is **not blocking** — but once
  added, the values become editable from the backend. Please confirm the correct production
  **phone / WhatsApp / email** here (the bundled default email may be a placeholder).

> Optional future extras (not rendered yet, mention only): social links
> (`instagram` / `twitter` / `facebook` URLs). Add later if wanted; the app will ignore
> unknown fields safely.

---

## 3. Summary

| Page | Endpoint | Type | Status |
|---|---|---|---|
| Privacy | `GET /content/privacy/` | long-form page | exists — **needs content** |
| Terms | `GET /content/terms/` | long-form page | exists — **needs content** |
| About | `GET /content/about/` | long-form page | exists — **needs content** |
| FAQ | `GET /content/faq/` | Q/A sections | exists — **needs content** |
| Contact Us | `GET /content/contact/` | structured fields | **NEW — please add** |

### Acceptance criteria
- [ ] All five endpoints honor `Accept-Language` (`ar` / `en`) and return localized text.
- [ ] `/content/{slug}/` returns `{slug, title, body, sections[]}` with `sections[]` carrying
      `{id, title, body, sort_order}`.
- [ ] FAQ returns its Q/A pairs as `sections` (title = question, body = answer).
- [ ] Unpublished page → 404 or empty body+sections (app shows "coming soon").
- [ ] `/content/contact/` returns `{phone, whatsapp, email, address?, working_hours?}`.
- [ ] Production support phone / WhatsApp / email confirmed.

Thanks! The app side is already wired for all of the above — it just needs the content and the
contact endpoint.
