import 'package:equatable/equatable.dart';
import 'package:sapbaq/features/products/data/models/product_option.dart';

/// Shared mosque reference embedded in every listing/contribution. Fields are
/// optional because different feeds include different subsets (water/equipment
/// carry area+governorate; maintenance carries an address).
class MosqueRef extends Equatable {
  final int id;
  final String name;
  final String area;
  final String governorate;
  final String address;

  const MosqueRef({
    required this.id,
    required this.name,
    this.area = '',
    this.governorate = '',
    this.address = '',
  });

  factory MosqueRef.fromJson(Map<String, dynamic> j) => MosqueRef(
    id: j['id'] as int,
    name: (j['name'] ?? '').toString(),
    area: (j['area'] ?? '').toString(),
    governorate: (j['governorate'] ?? '').toString(),
    address: (j['address'] ?? '').toString(),
  );

  /// "الحي، المحافظة" (whichever parts exist) for a one-line location subtitle.
  String get areaLine =>
      [area, governorate].where((s) => s.isNotEmpty).join('، ');

  @override
  List<Object?> get props => [id, name, area, governorate, address];
}

// ─── Tab 1: Bottled water ───────────────────────────────────────────────────

class WaterPackage extends Equatable {
  final String label;
  final String price;
  const WaterPackage({required this.label, required this.price});
  factory WaterPackage.fromJson(Map<String, dynamic> j) => WaterPackage(
    label: (j['label'] ?? '').toString(),
    price: (j['price'] ?? '0').toString(),
  );
  @override
  List<Object?> get props => [label, price];
}

class WaterCap extends Equatable {
  final int max;
  final int funded;
  final int remaining;
  const WaterCap({
    required this.max,
    required this.funded,
    required this.remaining,
  });
  factory WaterCap.fromJson(Map<String, dynamic> j) => WaterCap(
    max: (j['max'] as num?)?.toInt() ?? 0,
    funded: (j['funded'] as num?)?.toInt() ?? 0,
    remaining: (j['remaining'] as num?)?.toInt() ?? 0,
  );
  double get progress => max <= 0 ? 0 : (funded / max).clamp(0.0, 1.0);
  @override
  List<Object?> get props => [max, funded, remaining];
}

class WaterListing extends Equatable {
  final int restockFlagId;
  final MosqueRef mosque;
  final WaterPackage package;
  final WaterCap cap;

  const WaterListing({
    required this.restockFlagId,
    required this.mosque,
    required this.package,
    required this.cap,
  });

  factory WaterListing.fromJson(Map<String, dynamic> j) => WaterListing(
    restockFlagId: j['restock_flag_id'] as int,
    mosque: MosqueRef.fromJson(Map<String, dynamic>.from(j['mosque'] as Map)),
    package: WaterPackage.fromJson(
      Map<String, dynamic>.from(j['package'] as Map),
    ),
    cap: WaterCap.fromJson(Map<String, dynamic>.from(j['cap'] as Map)),
  );

  @override
  List<Object?> get props => [restockFlagId, mosque, package, cap];
}

// ─── Tab 2: Maintenance ─────────────────────────────────────────────────────

class MaintenanceContract extends Equatable {
  final String price;
  final int durationMonths;
  const MaintenanceContract({
    required this.price,
    required this.durationMonths,
  });
  factory MaintenanceContract.fromJson(Map<String, dynamic> j) =>
      MaintenanceContract(
        price: (j['price'] ?? '0').toString(),
        durationMonths: (j['duration_months'] as num?)?.toInt() ?? 12,
      );
  @override
  List<Object?> get props => [price, durationMonths];
}

class MaintenanceListing extends Equatable {
  final int caseId;
  final int equipmentId;
  final MosqueRef mosque;
  final String description;
  final String repairPrice;
  final MaintenanceContract? contract;

  const MaintenanceListing({
    required this.caseId,
    required this.equipmentId,
    required this.mosque,
    required this.description,
    required this.repairPrice,
    this.contract,
  });

  factory MaintenanceListing.fromJson(Map<String, dynamic> j) {
    final contract = j['contract'];
    return MaintenanceListing(
      caseId: j['case_id'] as int,
      equipmentId: j['equipment_id'] as int,
      mosque: MosqueRef.fromJson(Map<String, dynamic>.from(j['mosque'] as Map)),
      description: (j['description'] ?? '').toString(),
      repairPrice: (j['repair_price'] ?? '0').toString(),
      contract: contract is Map
          ? MaintenanceContract.fromJson(Map<String, dynamic>.from(contract))
          : null,
    );
  }

  @override
  List<Object?> get props => [
    caseId,
    equipmentId,
    mosque,
    description,
    repairPrice,
    contract,
  ];
}

// ─── Tab 3: Equipment ───────────────────────────────────────────────────────

/// How far a crowdfunded equipment campaign has got
/// (FLUTTER_EQUIPMENT_CROWDFUNDING §1). Every amount is a money *string* with
/// two decimals — never parse one into a double for display, only for maths.
class EquipmentFunding extends Equatable {
  /// The goal, frozen from the model's price when the request was approved.
  final String targetAmount;

  /// Paid contributions only — what the progress bar reflects.
  final String fundedAmount;

  /// Claimed by other donors right now, unpaid. Deliberately not shown as a
  /// number (it would read as "already funded"); its effect is inside
  /// [remaining].
  final String reservedAmount;

  /// target − funded − reserved: the ceiling for a new contribution.
  final String remaining;

  /// 0–100, computed from the paid amount alone.
  final int progress;

  const EquipmentFunding({
    this.targetAmount = '0',
    this.fundedAmount = '0',
    this.reservedAmount = '0',
    this.remaining = '0',
    this.progress = 0,
  });

  factory EquipmentFunding.fromJson(Map<String, dynamic> j) => EquipmentFunding(
    targetAmount: (j['target_amount'] ?? '0').toString(),
    fundedAmount: (j['funded_amount'] ?? '0').toString(),
    reservedAmount: (j['reserved_amount'] ?? '0').toString(),
    remaining: (j['remaining'] ?? '0').toString(),
    progress: (j['progress'] as num?)?.toInt() ?? 0,
  );

  /// For `LinearProgressIndicator`.
  double get ratio => progress.clamp(0, 100) / 100;

  double get remainingValue => double.tryParse(remaining) ?? 0;

  /// Nothing left to fund — the campaign is on its way out of the feed.
  bool get isClosed => remainingValue <= 0;

  @override
  List<Object?> get props => [
    targetAmount,
    fundedAmount,
    reservedAmount,
    remaining,
    progress,
  ];
}

class EquipmentListing extends Equatable {
  final int requestId;
  final MosqueRef mosque;
  final String equipmentType; // display string, e.g. "مبرّد ماء"
  final int equipmentTypeId;
  final String note;

  /// The product the manager settled on at approval.
  final ProductRef? product;

  /// The exact combination this campaign funds. Fixed by the regional manager
  /// at approval — the customer reads it, never picks it (delivery §6.4).
  final ListingVariant? variant;

  /// Null only on rows an older server build served (or an approved request
  /// with no model yet); such a campaign isn't fundable, so it isn't shown.
  final EquipmentFunding? funding;

  const EquipmentListing({
    required this.requestId,
    required this.mosque,
    required this.equipmentType,
    required this.equipmentTypeId,
    this.note = '',
    this.product,
    this.variant,
    this.funding,
  });

  /// A campaign can only be funded once the backend has published a variant and
  /// a goal for it. (The server already withholds unapproved requests from the
  /// feed, so this is belt-and-braces.)
  bool get isFundable => variant != null && funding != null;

  /// What the donor reads on the card: the product plus the chosen combination.
  String get title => [
    product?.name ?? equipmentType,
    if (variant != null && variant!.name.isNotEmpty) variant!.name,
  ].join(' — ');

  factory EquipmentListing.fromJson(Map<String, dynamic> j) => EquipmentListing(
    requestId: j['request_id'] as int,
    mosque: MosqueRef.fromJson(Map<String, dynamic>.from(j['mosque'] as Map)),
    equipmentType: (j['equipment_type'] ?? '').toString(),
    equipmentTypeId: (j['equipment_type_id'] as num?)?.toInt() ?? 0,
    note: (j['note'] ?? '').toString(),
    product: j['product'] is Map
        ? ProductRef.fromJson(Map<String, dynamic>.from(j['product'] as Map))
        : null,
    variant: j['variant'] is Map
        ? ListingVariant.fromJson(
            Map<String, dynamic>.from(j['variant'] as Map),
          )
        : null,
    funding: j['funding'] is Map
        ? EquipmentFunding.fromJson(
            Map<String, dynamic>.from(j['funding'] as Map),
          )
        : null,
  );

  @override
  List<Object?> get props => [
    requestId,
    mosque,
    equipmentType,
    equipmentTypeId,
    note,
    product,
    variant,
    funding,
  ];
}

/// The product a campaign settled on — just enough to name it.
class ProductRef extends Equatable {
  final int id;
  final String name;

  const ProductRef({required this.id, this.name = ''});

  factory ProductRef.fromJson(Map<String, dynamic> j) =>
      ProductRef(id: j['id'] as int? ?? 0, name: (j['name'] ?? '').toString());

  @override
  List<Object?> get props => [id, name];
}

/// The combination a campaign funds, as the feed serves it after approval:
/// the server-composed [name], a gallery already resolved by priority
/// (combination image → value images → product cover), and display-ready
/// specs (delivery §6.4). Read-only — the donor never picks it.
class ListingVariant extends Equatable {
  final int id;
  final String name;
  final String image;
  final List<String> images;
  final List<ProductAttribute> attributesDisplay;

  const ListingVariant({
    required this.id,
    this.name = '',
    this.image = '',
    this.images = const [],
    this.attributesDisplay = const [],
  });

  /// The gallery, never empty when there's at least a cover.
  List<String> get gallery =>
      images.isNotEmpty ? images : (image.isEmpty ? const [] : [image]);

  factory ListingVariant.fromJson(Map<String, dynamic> j) {
    final images = j['images'] is List
        ? (j['images'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
        : const <String>[];
    return ListingVariant(
      id: j['id'] as int? ?? 0,
      name: (j['name'] ?? '').toString(),
      image: (j['image'] ?? '').toString(),
      images: images,
      attributesDisplay: ProductAttribute.listFrom(j['attributes_display']),
    );
  }

  @override
  List<Object?> get props => [id, name, image, images, attributesDisplay];
}

// ─── Home teaser ────────────────────────────────────────────────────────────

class MarketplaceSummary extends Equatable {
  final int water;
  final int maintenance;
  final int equipment;
  const MarketplaceSummary({
    this.water = 0,
    this.maintenance = 0,
    this.equipment = 0,
  });
  factory MarketplaceSummary.fromJson(Map<String, dynamic> j) =>
      MarketplaceSummary(
        water: (j['water'] as num?)?.toInt() ?? 0,
        maintenance: (j['maintenance'] as num?)?.toInt() ?? 0,
        equipment: (j['equipment'] as num?)?.toInt() ?? 0,
      );
  int get total => water + maintenance + equipment;
  @override
  List<Object?> get props => [water, maintenance, equipment];
}

// ─── Contributions (buy-now) ────────────────────────────────────────────────

/// The `201` response of a `contribute/*` call — starts the payment hold.
class ContributionResult extends Equatable {
  final int contributionId;
  final String amount;
  final DateTime? expiresAt;
  final int holdSeconds;

  const ContributionResult({
    required this.contributionId,
    required this.amount,
    required this.expiresAt,
    required this.holdSeconds,
  });

  factory ContributionResult.fromJson(Map<String, dynamic> j) =>
      ContributionResult(
        contributionId: j['contribution_id'] as int,
        amount: (j['amount'] ?? '0').toString(),
        expiresAt: DateTime.tryParse((j['expires_at'] ?? '').toString()),
        holdSeconds: (j['hold_seconds'] as num?)?.toInt() ?? 300,
      );

  @override
  List<Object?> get props => [contributionId, amount, expiresAt, holdSeconds];
}

enum ContributionKind { water, maintenance, contract, equipment, unknown }

enum ContributionStatus {
  pending,
  paid,
  expired,
  cancelled,
  fulfilled,
  unknown,
}

class Contribution extends Equatable {
  final int id;
  final ContributionKind kind;
  final ContributionStatus status;
  final MosqueRef mosque;
  final String amount;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> details;
  final String? proofPhoto;

  const Contribution({
    required this.id,
    required this.kind,
    required this.status,
    required this.mosque,
    required this.amount,
    this.createdAt,
    this.expiresAt,
    this.details = const {},
    this.proofPhoto,
  });

  /// A photo of the funded item inside `details`, read in order of specificity:
  /// the picked `variant` since the unified catalogue, then the `product`, then
  /// the older `model` key. `variant` is legitimately null when the approved
  /// equipment product has no combinations at all (backend answers 2026-08-06)
  /// — the product's cover is the only photo that case ever has.
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

  /// The full-size cover photo of what this contribution funds, or null for the
  /// other kinds. Use for full-screen.
  String? get modelImage => _imageFrom('image');

  /// The cover's ~400px thumbnail for the card; falls back to the full image.
  String? get modelThumb => _imageFrom('image_thumb') ?? modelImage;

  /// Every photo of the funded unit (`details.variant.images`), in the server's
  /// order; falls back to the single [modelImage] — a variant-less product has
  /// only its cover.
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

  /// What this contribution funded, named the way the campaign named it: the
  /// product plus the picked combination. Empty for water and maintenance,
  /// which fund no catalogue item; falls back to the older `model` key.
  String get modelName {
    String name(dynamic node) =>
        node is Map ? (node['name'] ?? '').toString() : '';
    final composed = [
      name(details['product']),
      name(details['variant']),
    ].where((part) => part.isNotEmpty).join(' — ');
    return composed.isNotEmpty ? composed : name(details['model']);
  }

  factory Contribution.fromJson(Map<String, dynamic> j) => Contribution(
    id: j['id'] as int,
    kind: _kind((j['kind'] ?? '').toString()),
    status: _status((j['status'] ?? '').toString()),
    mosque: MosqueRef.fromJson(Map<String, dynamic>.from(j['mosque'] as Map)),
    amount: (j['amount'] ?? '0').toString(),
    createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()),
    expiresAt: DateTime.tryParse((j['expires_at'] ?? '').toString()),
    details: j['details'] is Map
        ? Map<String, dynamic>.from(j['details'] as Map)
        : const {},
    proofPhoto: (j['proof_photo'] as String?)?.isNotEmpty == true
        ? j['proof_photo'] as String
        : null,
  );

  bool get isPending => status == ContributionStatus.pending;

  /// Cancelled and expired contributions are over — nothing more will happen to
  /// them, so their card offers no action.
  bool get isTerminated =>
      status == ContributionStatus.cancelled ||
      status == ContributionStatus.expired;

  static ContributionKind _kind(String v) => switch (v.toUpperCase()) {
    'WATER' => ContributionKind.water,
    'MAINTENANCE' => ContributionKind.maintenance,
    'CONTRACT' => ContributionKind.contract,
    'EQUIPMENT' => ContributionKind.equipment,
    _ => ContributionKind.unknown,
  };

  static ContributionStatus _status(String v) => switch (v.toUpperCase()) {
    'PENDING' => ContributionStatus.pending,
    'PAID' => ContributionStatus.paid,
    'EXPIRED' => ContributionStatus.expired,
    'CANCELLED' => ContributionStatus.cancelled,
    'FULFILLED' => ContributionStatus.fulfilled,
    _ => ContributionStatus.unknown,
  };

  @override
  List<Object?> get props => [
    id,
    kind,
    status,
    mosque,
    amount,
    createdAt,
    expiresAt,
    details,
    proofPhoto,
  ];
}

// ─── Contribution detail (timeline) ─────────────────────────────────────────

/// Where a timeline step stands. The server sends exactly one `current` while a
/// contribution is in flight, and none once it has finished or ended.
enum ContributionStepState { done, current, pending, cancelled, expired }

/// One step of a contribution's journey, rendered as sent: the backend words
/// the titles in both languages and decides the order and the states, so there
/// is no status logic on this side — only drawing
/// (FLUTTER_EQUIPMENT_CROWDFUNDING, task 2 §2).
class ContributionStep extends Equatable {
  /// Stable step identifier (`paid`, `funding`, `installed`…). For icons and
  /// [meta] lookup only — never shown to the user.
  final String code;

  final String titleAr;
  final String titleEn;
  final ContributionStepState state;

  /// When the step happened; null while it hasn't.
  final DateTime? at;

  /// Step-specific extras: a share, funding figures, a proof photo, contract
  /// dates. May be empty.
  final Map<String, dynamic> meta;

  const ContributionStep({
    required this.code,
    this.titleAr = '',
    this.titleEn = '',
    this.state = ContributionStepState.pending,
    this.at,
    this.meta = const {},
  });

  String titleFor(String lang) =>
      lang == 'en' && titleEn.isNotEmpty ? titleEn : titleAr;

  String metaString(String key) => (meta[key] ?? '').toString();

  int? get metaProgress => (meta['progress'] as num?)?.toInt();

  factory ContributionStep.fromJson(Map<String, dynamic> j) => ContributionStep(
    code: (j['code'] ?? '').toString(),
    titleAr: (j['title_ar'] ?? '').toString(),
    titleEn: (j['title_en'] ?? '').toString(),
    state: _state((j['state'] ?? '').toString()),
    at: DateTime.tryParse((j['at'] ?? '').toString()),
    meta: j['meta'] is Map
        ? Map<String, dynamic>.from(j['meta'] as Map)
        : const {},
  );

  /// An unknown state draws as a plain, un-highlighted step rather than
  /// breaking the screen.
  static ContributionStepState _state(String v) => switch (v.toLowerCase()) {
    'done' => ContributionStepState.done,
    'current' => ContributionStepState.current,
    'cancelled' => ContributionStepState.cancelled,
    'expired' => ContributionStepState.expired,
    _ => ContributionStepState.pending,
  };

  @override
  List<Object?> get props => [code, titleAr, titleEn, state, at, meta];
}

/// `GET /marketplace/contributions/{id}/` — the list row plus its timeline.
class ContributionDetail extends Equatable {
  final Contribution contribution;
  final List<ContributionStep> timeline;

  const ContributionDetail({
    required this.contribution,
    this.timeline = const [],
  });

  factory ContributionDetail.fromJson(Map<String, dynamic> j) =>
      ContributionDetail(
        contribution: Contribution.fromJson(j),
        timeline: j['timeline'] is List
            ? (j['timeline'] as List)
                  .whereType<Map>()
                  .map(
                    (e) =>
                        ContributionStep.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList()
            : const [],
      );

  /// The proof of delivery/installation now travels on the final step's `meta`,
  /// not the contribution's old (always-empty) `proof_photo`.
  String? get proofPhoto {
    for (final step in timeline.reversed) {
      final photo = step.metaString('photo');
      if (photo.isNotEmpty) return photo;
    }
    return null;
  }

  /// The fulfilment statement that came with that photo, when there is one.
  String? get statement {
    for (final step in timeline.reversed) {
      final text = step.metaString('statement');
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  @override
  List<Object?> get props => [contribution, timeline];
}
