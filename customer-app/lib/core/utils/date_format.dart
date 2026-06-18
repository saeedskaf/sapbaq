/// Formats an ISO timestamp to a short local date "yyyy/MM/dd".
/// Returns an empty string when the input is null or unparseable.
String formatShortDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}/${two(date.month)}/${two(date.day)}';
}
