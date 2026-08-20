import 'package:flutter/material.dart';

/// Sapbaq palette — the logo's three colours, and grey.
///
/// The logo mark was measured, not guessed: 88–90% `#000000`, 6–10% `#87CDAA`,
/// 1–5% `#FFFFFF`, and nothing else but antialiasing. Those three values are
/// the brand, they appear at their exact values, and they are never lightened,
/// darkened, tinted or blended.
///
/// Everything structural comes from the grey ramp instead — held at **zero
/// saturation**. Greys are not shades of the brand: they are a separate
/// functional axis, which is how every disciplined system (Apple, Spotify,
/// Uber, Nike) can hold a two- or three-colour identity and still build a
/// whole interface. Tinting them, as this palette used to, is what made the
/// mint impossible to see — nothing on screen contrasted with it.
///
/// The role names below ([background], [textPrimary], …) are aliases onto
/// those two groups. Widgets keep reading `context.colors.X`; only the values
/// underneath them changed.
class ColorsCustom {
  ColorsCustom._();

  // ── The brand: three colours, exact ──────────────────────────────────────

  /// The logo's ground. Also the app's dark-mode page and light-mode text —
  /// the identity forms the interface's edges rather than sitting on top of
  /// it.
  static const Color black = Color(0xFF000000);

  /// The logo's mark. The only hue in the entire app: the primary action, the
  /// selected state, the brand marks. Never a foreground, never a wash.
  static const Color brandMint = Color(0xFF87CDAA);

  /// The logo's wordmark. Also the light-mode card and the dark-mode text.
  static const Color white = Color(0xFFFFFFFF);

  // ── Neutral ramp — zero saturation, no hue at all ────────────────────────
  // Ten steps between [white] and [black], which are themselves the ramp's
  // endpoints. Roles below index into this; nothing else may.

  static const Color grey50 = Color(0xFFF7F7F7);
  static const Color grey100 = Color(0xFFEFEFEF);
  static const Color grey200 = Color(0xFFE2E2E2);
  static const Color grey300 = Color(0xFFCBCBCB);
  static const Color grey400 = Color(0xFFA3A3A3);
  static const Color grey500 = Color(0xFF737373);
  static const Color grey600 = Color(0xFF525252);
  static const Color grey700 = Color(0xFF3A3A3A);
  static const Color grey800 = Color(0xFF262626);
  static const Color grey900 = Color(0xFF171717);

  // ── Roles — light ────────────────────────────────────────────────────────

  /// Page ground. [grey50] rather than pure white so a [surface] card still
  /// separates from the page without needing a border everywhere; both are
  /// zero-saturation, so the one-hue rule holds either way.
  static const Color background = grey50;

  /// Card, sheet and app-bar fill — the brand's white.
  static const Color surface = white;

  /// Input fills, inactive chips, quiet filled areas.
  static const Color surfaceVariant = grey100;

  /// Hairline borders and dividers.
  static const Color border = grey200;

  /// The tile behind `contain`-fitted product photos. Deliberately light in
  /// BOTH themes: supplier photos are mostly shot on white, and a light well
  /// lets them blend instead of floating as hard white rectangles.
  static const Color imageWell = grey100;

  /// Inputs while focused. Neutral — the mint focus *ring* carries the state.
  static const Color inputFocusFill = grey100;

  static const Color textPrimary = black;
  static const Color textSecondary = grey600;
  static const Color textHint = grey400;

  /// Foreground on a dark fill.
  static const Color textOnPrimary = white;

  /// Immersive brand surfaces — splash, auth header. The logo's own ground,
  /// so the logo card dissolves into it with no seam.
  static const Color ink = black;

  /// Strong foreground on light surfaces.
  static const Color primary = black;

  /// The one foreground allowed on [brandMint]. Every coloured fill in this
  /// system carries black text, which is what lets each colour have a single
  /// value instead of a light and a dark variant.
  static const Color onMint = black;

  // ── Roles — dark ─────────────────────────────────────────────────────────
  // The same ramp, indexed from the other end. Not a second palette.

  /// Page ground — the logo's black, so the app reads as an extension of the
  /// mark itself.
  static const Color darkBackground = black;
  static const Color darkSurface = grey900;
  static const Color darkSurfaceVariant = grey800;
  static const Color darkBorder = grey700;

  static const Color darkTextPrimary = white;
  static const Color darkTextSecondary = grey400;
  static const Color darkTextHint = grey500;

  /// Strong foreground on dark surfaces.
  static const Color primaryOnDark = white;

  // ── Semantic — outside the brand, by decision ────────────────────────────
  // Order and case states are not tied to the identity. Both alarms below are
  // fills that carry black text, exactly like the mint, so neither needs a
  // per-mode variant.

  /// Done / in progress. The brand mint does this job: when the identity is
  /// already green, a second green for success weakens both.
  static const Color success = brandMint;

  /// Pending, needs action.
  static const Color warning = Color(0xFFF5A524);

  /// Failed, cancelled, destructive. Deliberately dark enough to work two
  /// ways: legible as a solid fill under [white] (4.8:1) *and* legible as
  /// text or an icon on a light ground (4.8:1). No single value can do that
  /// while also carrying black, which is why red is the one signal whose
  /// label is white.
  static const Color error = Color(0xFFD92D20);

  /// The same red, re-indexed for a dark ground — identical hue (4°), the
  /// lightness raised until it reads.
  ///
  /// This is the one signal that needs a second value, and only because it is
  /// the one signal used as a **foreground**. A fill needs no variant: it is
  /// painted at [error] and labelled by [onSignal] in both modes. But red text
  /// or a red icon has to clear 4.5:1 against whatever is behind it, and no
  /// single red can do that on both [surface] (#FFFFFF) and [darkSurface]
  /// (#171717) — the two grounds pull in opposite directions and the best any
  /// single value manages is 4.23:1 on each. [error] itself is tuned for the
  /// light side (4.83:1 there, 3.71:1 on a dark card, dimmer than [grey500]).
  /// This value covers the dark side: 6.43:1 on [darkSurface], 7.54:1 on
  /// [darkBackground], 5.43:1 on [darkSurfaceVariant].
  ///
  /// Read it through `context.colors.danger`, never directly — the role picks
  /// the right end for the active brightness.
  static const Color errorOnDark = Color(0xFFF97066);

  /// Whether [c] is one of the system's **signal fills** — the mint or one of
  /// the two alarms — as opposed to a neutral from the grey ramp.
  ///
  /// Signals are painted solid and always carry [black]; black beats white on
  /// all three (11.3:1, 10.3:1 and 5.4:1 against 1.9:1, 2.0:1 and 3.9:1). A
  /// status that resolves to a neutral instead stays quiet: a grey fill with
  /// the neutral itself as the label.
  static bool isSignal(Color c) => c == brandMint || c == warning || c == error;

  /// The legible label for a solid signal fill.
  ///
  /// Black on the mint (11.3:1) and the amber (10.3:1); white on the red
  /// (4.8:1), which is dark enough to need it. Those two are the only
  /// foreground values in the system, and neither is ever a shade of
  /// anything — they are the logo's own black and white.
  static Color onSignal(Color c) => c == error ? white : black;

  // ── Overlays — the only transparencies in the system ─────────────────────
  // Four named levels replace the improvised alphas that used to be picked
  // per call site (0.05, 0.06, 0.08, 0.12, 0.18, 0.22, 0.28, 0.55…). Each is
  // the logo's own black or white at a fixed strength, so a transparency is
  // still one of the three brand colours rather than a fourth value.

  /// Dimming behind a modal, or over a photo so white content reads on it.
  static const Color scrim = Color(0x8C000000);

  /// The deep dim of an immersive media viewer.
  static const Color scrimHeavy = Color(0xF0000000);

  /// Card, sheet and floating-bar shadow.
  static const Color shadow = Color(0x14000000);

  /// The hairline highlight along a translucent surface's edge, and quiet
  /// fills over a dark ground.
  static const Color glassEdge = Color(0x8CFFFFFF);
}
