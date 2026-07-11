import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';

/// Guards the mint-first system's core accessibility rule: mint is only ever a
/// FILL under a dark foreground, and the brand green reads on light surfaces.
/// Every pairing below must clear the WCAG AA text threshold (4.5:1).
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

void main() {
  test('brand pairings meet WCAG AA (4.5:1)', () {
    // Button/label text on the mint fill.
    expect(
      contrastRatio(ColorsCustom.onMint, ColorsCustom.brandMint),
      greaterThanOrEqualTo(4.5),
    );
    // Brand green as foreground text/icons on the light surface.
    expect(
      contrastRatio(ColorsCustom.primary, ColorsCustom.surface),
      greaterThanOrEqualTo(4.5),
    );
    // White content on the deep-green hero surfaces.
    expect(
      contrastRatio(ColorsCustom.textOnPrimary, ColorsCustom.primary),
      greaterThanOrEqualTo(4.5),
    );
  });
}
