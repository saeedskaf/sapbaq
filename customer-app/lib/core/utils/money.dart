/// The app's single answer to "how many decimals does an amount have?".
///
/// The API sends every amount with two decimals — `"320.00"`, `"1.20"` — and
/// always has. Amounts are normalised on the way in so that stays true no
/// matter which endpoint they arrive from.
///
/// This exists because of a mistake worth remembering. The published schema
/// declares money fields as `\d{0,3}` after the point, so an audit of all
/// thirty-nine of them concluded the wire format was three decimals and one new
/// endpoint had broken ranks. It hadn't: the pattern describes the *storage*
/// precision of the underlying decimal column, and the serializer formats to two
/// on output. Normalising to three then made the payment sheet the only screen
/// in the app saying `25.000` where every other said `25.00` — the exact
/// inconsistency the normaliser was added to prevent, produced by the
/// normaliser. Checking a live response settled in seconds what reading the
/// schema got backwards.
///
/// What survives is the useful half: display precision is now something the app
/// decides in one place. If the business ever wants three — or wants two because
/// `8.600` has been misread as eight thousand six hundred — it is [decimals]
/// here, once, and not a negotiation over thirty-nine backend fields.
class Money {
  Money._();

  /// Decimal places shown to the customer. Matches what the API sends today.
  /// Changing this changes every amount that passes through [format].
  static const int decimals = 2;

  /// An amount string as the customer should read it.
  ///
  /// An input that doesn't parse comes back untouched: showing the server's own
  /// text beats inventing a `0.000` for something we failed to understand.
  static String format(String raw) {
    final trimmed = raw.trim();
    final value = num.tryParse(trimmed);
    if (value == null) return trimmed;
    return value.toStringAsFixed(decimals);
  }
}
