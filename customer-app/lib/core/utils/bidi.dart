/// Unicode bidirectional isolate controls (kept as explicit code points so the
/// invisible characters can't be silently stripped from source).
final String _lri = String.fromCharCode(0x2066); // LEFT-TO-RIGHT ISOLATE
final String _pdi = String.fromCharCode(0x2069); // POP DIRECTIONAL ISOLATE

/// Wraps [text] in a Unicode left-to-right isolate (U+2066 … U+2069) so a run
/// that begins with a neutral character — e.g. a phone number's leading "+" —
/// renders left-to-right even when embedded in an RTL (Arabic) sentence.
///
/// Without it, "+96512345678" placed inside Arabic text has its "+" pushed to
/// the visual end of the number; the isolate keeps the whole phone as one LTR
/// unit with the "+" at the start.
String ltrIsolate(String text) => text.isEmpty ? text : '$_lri$text$_pdi';
