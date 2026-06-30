import 'package:equatable/equatable.dart';
import 'package:sapbaq/features/info/info_content.dart';

/// Support contact details for the "Contact us" screen (`GET /content/contact/`).
/// [address] and [workingHours] are optional (bilingual, follow Accept-Language)
/// and are only shown when present.
class ContactInfo extends Equatable {
  final String phone;
  final String whatsapp;
  final String email;
  final String address;
  final String workingHours;

  const ContactInfo({
    required this.phone,
    required this.whatsapp,
    required this.email,
    this.address = '',
    this.workingHours = '',
  });

  /// Built-in defaults, used until the backend responds (and if it has no
  /// contact entry) so the user can always reach support.
  const ContactInfo.fallback()
    : phone = InfoContent.supportPhone,
      whatsapp = InfoContent.supportWhatsapp,
      email = InfoContent.supportEmail,
      address = '',
      workingHours = '';

  bool get hasPhone => phone.isNotEmpty;
  bool get hasWhatsapp => whatsapp.isNotEmpty;
  bool get hasEmail => email.isNotEmpty;

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    const fallback = ContactInfo.fallback();
    String pick(String key, String fb) {
      final v = (json[key] ?? '').toString().trim();
      return v.isEmpty ? fb : v;
    }

    return ContactInfo(
      phone: pick('phone', fallback.phone),
      whatsapp: pick('whatsapp', fallback.whatsapp),
      email: pick('email', fallback.email),
      address: (json['address'] ?? '').toString().trim(),
      workingHours: (json['working_hours'] ?? '').toString().trim(),
    );
  }

  @override
  List<Object?> get props => [phone, whatsapp, email, address, workingHours];
}
