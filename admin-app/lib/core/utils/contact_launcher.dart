import 'package:url_launcher/url_launcher.dart';

/// Opens the phone dialer for [phone] (a `tel:` link). Returns false when the
/// number is empty or no app can handle it (the caller shows a fallback).
Future<bool> dialPhone(String phone) async {
  final cleaned = phone.trim();
  if (cleaned.isEmpty) return false;
  final uri = Uri(scheme: 'tel', path: cleaned);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri);
}

/// Opens a WhatsApp chat with [phone] via `wa.me`. wa.me wants digits only, so
/// the leading `+`, spaces and dashes are stripped. Returns false on failure.
Future<bool> openWhatsApp(String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return false;
  final uri = Uri.parse('https://wa.me/$digits');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
