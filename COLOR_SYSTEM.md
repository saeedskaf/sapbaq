# Sapbaq color system — mint-first

One brand hue (the logo mint), disciplined neutrals, and the minimum status
signals. Both apps (`customer-app`, `admin-app`) share this system via an
identical `lib/core/theme/colors_custom.dart` and the theme-aware
`context.colors` (`ThemeColors`) extension.

## Principles

1. **Mint is the identity + primary-action color — used sparingly (~10%).**
   Primary buttons, FAB, active/selected states, brand moments. Scarcity is what
   makes it read as a signal.
2. **60-30-10:** ~60% neutral canvas, ~30% surfaces, ~10% mint accents.
3. **One accent, one meaning.** Mint always = primary action / active. Never
   decorative.
4. **Accessibility is a hard rule.** Text ≥ 4.5:1, UI ≥ 3:1
   (`test/color_contrast_test.dart` enforces the brand pairings).
5. **One brand hue as a tonal ramp** — no second green, no gold, no cyan.

## The brand ramp (one hue)

| Token | Hex | Use |
|---|---|---|
| `onMint` | `#06130D` | Foreground on mint fills (button text) |
| `primary` | `#0E5E44` | **The only** brand foreground on light (text/icons/selected); replaces the retired off-logo `#1F7A52` |
| `primaryDark` | `#14573A` | Marker/stroke depth |
| `primaryLight` | `#4FA87D` | Mid ramp step |
| `brandMint` | `#87CDAA` | **Hero fill** — buttons, FAB, active controls (sampled from the logo) |
| `secondaryLight` | `#DCF2E6` | Mint tint — icon chips, selected-row wash (light) |
| `inputFocusFill` | `#EFF9F3` | Focused input wash |

In **dark** mode the brand foreground is the mint itself (`primaryOnDark`); the
mint fill + `onMint` pairing is unchanged.

## Neutral anchors

`ink #0B0F0D` (splash, auth headers, immersive) · `background` · `surface` ·
`surfaceVariant` · `border` · `textPrimary/Secondary/Hint` — each with a dark
counterpart (`darkBackground #0F1411`, `darkSurface #161D19`, …).

## Status — reduced to the essentials

| Signal | Token | Meaning |
|---|---|---|
| Amber | `warning #E0A33E` | Pending / needs action; rating stars |
| Brand green | `primary` / `success #2E9E6B` | In progress / done |
| Red | `error #C8463C` | Cancelled / destructive |
| Neutral | `textHint` | Inactive / past |

Retired: `secondary`/`accentGold` (gold), `info` (cyan), `brandGradient`.

## Do / Don't

- **Do** reach for `context.colors.X` (theme-aware) for neutrals and brand
  foreground; use `ColorsCustom.X` only for the fixed brand/status colors.
- **Do** put mint behind dark (`onMint`) content only.
- **Don't** use mint as text/icon on a light surface (fails contrast — use
  `primary`).
- **Don't** introduce a new hue for a one-off accent. Reuse the ramp, amber, or
  red.
- **Don't** hardcode hex in screens — everything flows through the tokens.

## Login = the reference

Both apps open on the same brand moment: an **ink header + white/mint-on-black
logo lockup + a mint primary button**. Splash is solid `ink`.
