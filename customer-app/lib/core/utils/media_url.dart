import 'package:sapbaq/core/config/environment.dart';

/// Resolves a possibly-relative media path (e.g. "/media/x.jpg") to an absolute
/// URL using the API host. Some endpoints return absolute URLs, others relative.
String? resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final origin = Uri.parse(Environment.baseUrl).origin; // e.g. https://host
  return path.startsWith('/') ? '$origin$path' : '$origin/$path';
}
