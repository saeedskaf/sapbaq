import 'package:equatable/equatable.dart';
import 'package:sapbaq_admin/features/admin/data/models/mosque_need.dart';
import 'package:sapbaq_admin/features/auth/data/models/user.dart' show StaffRef;

/// `GET /admin/marketplace/contributions/` — a paid customer contribution
/// awaiting fulfilment. `kind` is one of WATER / MAINTENANCE / EQUIPMENT
/// (CONTRACT self-fulfils and never appears here). [details] varies by kind.
class AdminContribution extends Equatable {
  final int id;
  final String reference;
  final String kind; // WATER | MAINTENANCE | EQUIPMENT
  final String status; // PENDING | PAID | FULFILLED | EXPIRED | CANCELLED
  final StaffRef? customer;
  final NeedMosque? mosque;
  final String amount; // string money "45.00"
  final DateTime? createdAt;
  final DateTime? paidAt;
  final Map<String, dynamic> details;
  final String? proofPhoto;

  const AdminContribution({
    required this.id,
    this.reference = '',
    required this.kind,
    required this.status,
    this.customer,
    this.mosque,
    this.amount = '',
    this.createdAt,
    this.paidAt,
    this.details = const {},
    this.proofPhoto,
  });

  bool get isPaid => status == 'PAID';

  factory AdminContribution.fromJson(Map<String, dynamic> j) =>
      AdminContribution(
        id: j['id'] as int? ?? 0,
        reference: (j['reference'] ?? '').toString(),
        kind: (j['kind'] ?? '').toString().toUpperCase(),
        status: (j['status'] ?? '').toString().toUpperCase(),
        customer: j['customer'] is Map
            ? StaffRef.fromJson(Map<String, dynamic>.from(j['customer'] as Map))
            : null,
        mosque: j['mosque'] is Map
            ? NeedMosque.fromJson(Map<String, dynamic>.from(j['mosque'] as Map))
            : null,
        amount: (j['amount'] ?? '').toString(),
        createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
        paidAt: DateTime.tryParse((j['paid_at'] ?? '').toString()),
        details: j['details'] is Map
            ? Map<String, dynamic>.from(j['details'] as Map)
            : const {},
        proofPhoto: (j['proof_photo'] as String?)?.isNotEmpty == true
            ? j['proof_photo'] as String
            : null,
      );

  /// The photo of what the customer funded, full-size, or null for the other
  /// kinds — used for the full-screen view. Read in order of specificity: the
  /// picked combination, then the product, then the pre-unification `model`
  /// node, so the ledger shows the same unit whichever shape the row carries.
  String? get modelImage => _imageFrom('image');

  /// The ~400px `image_thumb` derivative for the list card, in the same order;
  /// falls back to the full images when no derivative is present (old rows, or a
  /// build without the field). See backend reply §3.
  String? get modelThumb => _imageFrom('image_thumb') ?? modelImage;

  /// What this contribution funded, as the unified catalogue names it: the
  /// product plus the picked combination. `variant` is legitimately null when
  /// the approved product has no combinations at all (backend answers
  /// 2026-08-06) — the product alone is the whole answer there. Empty for a
  /// pre-unification row, which carries only `model` and `equipment_type`.
  String get _catalogName {
    String name(dynamic node) =>
        node is Map ? (node['name'] ?? '').toString() : '';
    return [
      name(details['product']),
      name(details['variant']),
    ].where((part) => part.isNotEmpty).join(' — ');
  }

  /// Every photo of the funded combination (`details.variant.images`), in the
  /// server's order (backend answers 2026-08-04 §2); falls back to the single
  /// [modelImage].
  List<String> get modelImages {
    final variant = details['variant'];
    if (variant is Map && variant['images'] is List) {
      final urls = [
        for (final image in variant['images'] as List)
          if (image.toString().isNotEmpty) image.toString(),
      ];
      if (urls.isNotEmpty) return urls;
    }
    final single = modelImage;
    return single == null ? const [] : [single];
  }

  String? _imageFrom(String key) {
    for (final node in [
      details['variant'],
      details['product'],
      details['model'],
    ]) {
      if (node is! Map) continue;
      final value = (node[key] ?? '').toString();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  /// A one-line, kind-specific summary of [details] for the card.
  String get detailSummary {
    String s(String key) => (details[key] ?? '').toString();
    switch (kind) {
      case 'WATER':
        final packages = s('packages');
        final label = s('package_label');
        return [packages, label].where((e) => e.isNotEmpty).join(' × ');
      case 'MAINTENANCE':
        return [
          s('equipment_code'),
          s('description'),
        ].where((e) => e.isNotEmpty).join(' — ');
      case 'EQUIPMENT':
        // The funded unit's own name says more than the generic type it
        // belongs to ("مبرّد ماء خارجي — أسود" over "مبرّد ماء"), and it is the
        // only line a variant-less row has. A pre-unification row keeps the
        // type it always showed.
        final name = _catalogName;
        return name.isNotEmpty ? name : s('equipment_type');
      default:
        return '';
    }
  }

  @override
  List<Object?> get props => [id, kind, status];
}
