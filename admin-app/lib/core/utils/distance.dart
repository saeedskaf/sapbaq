/// Straight-line distance from the signed-in user to a row's mosque, as the
/// server computes it when the request carries `lat/lng`
/// (FLUTTER_NEAREST_FIRST_SORTING §1).
///
/// The payload type isn't pinned yet — a number in the examples, but money-like
/// fields elsewhere arrive as strings — so both are accepted. Null means "no
/// coordinates for that mosque" (the row sorts last) or "we sent no location".
double? parseDistanceKm(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

/// "1.5" under 10 km, "12" above — one decimal is meaningful walking distance,
/// beyond that it's noise on a straight-line estimate. Western digits, matching
/// how the app renders every other number.
String formatDistanceKm(double km) {
  if (km.isNaN || km.isInfinite || km < 0) return '';
  return km < 10 ? km.toStringAsFixed(1) : km.round().toString();
}
