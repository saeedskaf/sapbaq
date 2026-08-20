import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';

/// Guards the palette's structural promise: the logo's three colours, a grey
/// ramp carrying no hue at all, and two alarms — nothing else.
double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);

double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Every opaque colour the palette exposes. A token added without being listed
/// here escapes the hue sweep below, so keep it current.
const Map<String, Color> _palette = {
  'black': ColorsCustom.black,
  'brandMint': ColorsCustom.brandMint,
  'white': ColorsCustom.white,
  'grey50': ColorsCustom.grey50,
  'grey100': ColorsCustom.grey100,
  'grey200': ColorsCustom.grey200,
  'grey300': ColorsCustom.grey300,
  'grey400': ColorsCustom.grey400,
  'grey500': ColorsCustom.grey500,
  'grey600': ColorsCustom.grey600,
  'grey700': ColorsCustom.grey700,
  'grey800': ColorsCustom.grey800,
  'grey900': ColorsCustom.grey900,
  'warning': ColorsCustom.warning,
  'error': ColorsCustom.error,
  'errorOnDark': ColorsCustom.errorOnDark,
};

void main() {
  test('the palette holds the three logo colours at their exact values', () {
    // Measured from assets/images/logo/sapbaq_logo_mark.png: 88–90% black,
    // 6–10% mint, 1–5% white, and nothing else but antialiasing.
    expect(ColorsCustom.black, const Color(0xFF000000));
    expect(ColorsCustom.brandMint, const Color(0xFF87CDAA));
    expect(ColorsCustom.white, const Color(0xFFFFFFFF));
  });

  test('the brand colours are never shaded — roles alias them exactly', () {
    // Each of the three appears somewhere as itself, not as a near-miss.
    expect(ColorsCustom.ink, ColorsCustom.black);
    expect(ColorsCustom.primary, ColorsCustom.black);
    expect(ColorsCustom.textPrimary, ColorsCustom.black);
    expect(ColorsCustom.darkBackground, ColorsCustom.black);
    expect(ColorsCustom.surface, ColorsCustom.white);
    expect(ColorsCustom.darkTextPrimary, ColorsCustom.white);
    expect(ColorsCustom.primaryOnDark, ColorsCustom.white);
    expect(ColorsCustom.success, ColorsCustom.brandMint);
  });

  test('the ramp carries no hue at all', () {
    // The regression this exists to prevent ran for months: every token in the
    // palette sat at hue 140-154, so the "greys" were green and the mint had
    // nothing to contrast against.
    const ramp = {
      'grey50': ColorsCustom.grey50,
      'grey100': ColorsCustom.grey100,
      'grey200': ColorsCustom.grey200,
      'grey300': ColorsCustom.grey300,
      'grey400': ColorsCustom.grey400,
      'grey500': ColorsCustom.grey500,
      'grey600': ColorsCustom.grey600,
      'grey700': ColorsCustom.grey700,
      'grey800': ColorsCustom.grey800,
      'grey900': ColorsCustom.grey900,
    };
    ramp.forEach((name, c) {
      expect(
        HSLColor.fromColor(c).saturation,
        0.0,
        reason: '$name is not a pure neutral',
      );
      expect(c.r, c.g, reason: '$name has a colour cast');
      expect(c.g, c.b, reason: '$name has a colour cast');
    });
  });

  test('the ramp is monotonic, so roles cannot pick a wrong step', () {
    const ordered = [
      ColorsCustom.white,
      ColorsCustom.grey50,
      ColorsCustom.grey100,
      ColorsCustom.grey200,
      ColorsCustom.grey300,
      ColorsCustom.grey400,
      ColorsCustom.grey500,
      ColorsCustom.grey600,
      ColorsCustom.grey700,
      ColorsCustom.grey800,
      ColorsCustom.grey900,
      ColorsCustom.black,
    ];
    for (var i = 1; i < ordered.length; i++) {
      expect(
        _luminance(ordered[i]),
        lessThan(_luminance(ordered[i - 1])),
        reason: 'step $i is not darker than the one before it',
      );
    }
  });

  test('the mint is the only hue outside the two alarms', () {
    final hued = <String>[];
    _palette.forEach((name, c) {
      if (HSLColor.fromColor(c).saturation > 0.05) hued.add(name);
    });
    // Three alarm entries, not four colours: errorOnDark is the same red at
    // the same hue, held at a second lightness because it is the one signal
    // ever painted as a foreground. See the test below.
    expect(
      hued,
      unorderedEquals(['brandMint', 'warning', 'error', 'errorOnDark']),
    );
    expect(
      (HSLColor.fromColor(ColorsCustom.errorOnDark).hue -
              HSLColor.fromColor(ColorsCustom.error).hue)
          .abs(),
      lessThan(1.0),
      reason: 'the dark-ground red must be the same red, not a new one',
    );
  });

  test('every signal fill is legible under the label onSignal picks', () {
    for (final signal in [
      ColorsCustom.brandMint,
      ColorsCustom.warning,
      ColorsCustom.error,
    ]) {
      expect(ColorsCustom.isSignal(signal), isTrue);
      expect(
        contrastRatio(ColorsCustom.onSignal(signal), signal),
        greaterThanOrEqualTo(4.5),
        reason: 'a signal fill must carry its label',
      );
    }
    // And onSignal picks the better of the two every time — this is what makes
    // a single value per colour possible, with no light and dark variant.
    for (final signal in [
      ColorsCustom.brandMint,
      ColorsCustom.warning,
      ColorsCustom.error,
    ]) {
      final chosen = contrastRatio(ColorsCustom.onSignal(signal), signal);
      final other = contrastRatio(
        ColorsCustom.onSignal(signal) == ColorsCustom.black
            ? ColorsCustom.white
            : ColorsCustom.black,
        signal,
      );
      expect(chosen, greaterThanOrEqualTo(other));
    }
  });

  test('the mint is a fill, never a foreground on a light ground', () {
    // 1.85:1. Any mint text or icon on a card is a bug, and in dark mode the
    // neutral foreground is white, so a mint surface that inherits it breaks
    // the same way.
    expect(
      contrastRatio(ColorsCustom.brandMint, ColorsCustom.surface),
      lessThan(3),
    );
    expect(
      contrastRatio(ColorsCustom.white, ColorsCustom.brandMint),
      lessThan(4.5),
    );
  });

  test('text reads on its own surface in both modes', () {
    expect(
      contrastRatio(ColorsCustom.textPrimary, ColorsCustom.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(ColorsCustom.textSecondary, ColorsCustom.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(ColorsCustom.darkTextPrimary, ColorsCustom.darkSurface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(ColorsCustom.darkTextSecondary, ColorsCustom.darkSurface),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('the red doubles as a foreground, which is why it is the dark one', () {
    // Destructive icons and text are still painted in it on a light ground.
    expect(
      contrastRatio(ColorsCustom.error, ColorsCustom.surface),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('the red is the one signal that needs a second value', () {
    // Being tuned for the light side is exactly what makes [error] fail on the
    // dark one — 3.71:1 on a dark card, dimmer than the grey500 hint it
    // replaced, which is how a struck price came to read as unstruck in dark
    // mode. [errorOnDark] covers every dark ground the app paints.
    expect(
      contrastRatio(ColorsCustom.error, ColorsCustom.darkSurface),
      lessThan(4.5),
    );
    for (final ground in [
      ColorsCustom.darkSurface,
      ColorsCustom.darkBackground,
      ColorsCustom.darkSurfaceVariant,
    ]) {
      expect(
        contrastRatio(ColorsCustom.errorOnDark, ground),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('no single red could have served both grounds', () {
    // The justification for the pair, held as an assertion so nobody "tidies"
    // it back into one value: sweep every red between the two and the best any
    // single one manages on both #FFFFFF and #171717 is 4.23:1.
    var best = 0.0;
    for (var r = 0; r <= 255; r++) {
      for (var g = 0; g <= 255; g += 5) {
        final c = Color.fromARGB(255, r, g, (g * 0.7).round());
        final both = math.min(
          contrastRatio(c, ColorsCustom.surface),
          contrastRatio(c, ColorsCustom.darkSurface),
        );
        if (both > best) best = both;
      }
    }
    expect(best, lessThan(4.5));
  });

  test('overlays are the brand black and white, not new values', () {
    for (final o in [
      ColorsCustom.scrim,
      ColorsCustom.scrimHeavy,
      ColorsCustom.shadow,
    ]) {
      expect(o.r, ColorsCustom.black.r);
      expect(o.g, ColorsCustom.black.g);
      expect(o.b, ColorsCustom.black.b);
      expect(o.a, lessThan(1.0));
    }
    expect(ColorsCustom.glassEdge.r, ColorsCustom.white.r);
    expect(ColorsCustom.glassEdge.a, lessThan(1.0));
  });
}
