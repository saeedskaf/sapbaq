/// Formats an ISO timestamp to a short local date "yyyy/MM/dd".
/// Returns an empty string when the input is null or unparseable.
String formatShortDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}/${two(date.month)}/${two(date.day)}';
}

/// Formats an ISO timestamp to a local date + 24h time "yyyy/MM/dd HH:mm".
/// Returns an empty string when the input is null or unparseable.
String formatShortDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}/${two(date.month)}/${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}';
}

/// Formats a [DateTime] to a local date + 24h time "yyyy/MM/dd HH:mm".
/// Returns an empty string when the input is null.
String formatDateTimeOf(DateTime? date) {
  if (date == null) return '';
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}/${two(d.month)}/${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}
