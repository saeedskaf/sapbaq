import 'package:url_launcher/url_launcher.dart';

/// Opens a ready-made maps URL (e.g. a mosque's `maps_url`) in the device's
/// external maps app/browser. Returns false when there's no URL to open (the
/// caller should then fall back to showing the textual address).
Future<bool> openMapsUrl(String? mapsUrl) async {
  if (mapsUrl == null || mapsUrl.isEmpty) return false;
  final uri = Uri.tryParse(mapsUrl);
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
