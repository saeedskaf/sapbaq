import 'package:equatable/equatable.dart';

/// How an option type's values are presented (delivery §1.2 rule 7). An
/// unrecognised value renders as [chip] — the server may add styles we don't
/// know yet, and a missing picker is worse than a plain one.
enum OptionDisplay {
  chip,
  swatch,
  dropdown;

  static OptionDisplay from(String? raw) => switch (raw?.toUpperCase()) {
    'SWATCH' => OptionDisplay.swatch,
    'DROPDOWN' => OptionDisplay.dropdown,
    _ => OptionDisplay.chip,
  };
}

/// One choosable value inside a [ProductOptionType] — "أسود", "L", "3 حنفيات".
///
/// [image] is the thumbnail shown *inside* the chip; [swatchHex] is the colour
/// fallback when there's no image. The server sends `""` (not null) for an
/// empty swatch, so emptiness — never nullness — is the test.
class ProductOptionValue extends Equatable {
  final int id;
  final String value;
  final String swatchHex;
  final String? image;
  final int sortOrder;

  const ProductOptionValue({
    required this.id,
    this.value = '',
    this.swatchHex = '',
    this.image,
    this.sortOrder = 0,
  });

  bool get hasImage => image != null && image!.isNotEmpty;
  bool get hasSwatch => swatchHex.isNotEmpty;

  factory ProductOptionValue.fromJson(Map<String, dynamic> j) =>
      ProductOptionValue(
        id: j['id'] as int? ?? 0,
        value: (j['value'] ?? '').toString(),
        swatchHex: (j['swatch_hex'] ?? '').toString(),
        image: (j['image'] as String?)?.isEmpty ?? true
            ? null
            : j['image'] as String,
        sortOrder: j['sort_order'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [id, value, swatchHex, image, sortOrder];
}

/// One axis of choice on a product — "اللون", "عدد الأحواض". The server sends
/// the axes in `sort_order`, and **that order is the order the customer picks
/// in** (delivery §1.2 rule 1); never re-sort them here.
class ProductOptionType extends Equatable {
  final int id;
  final String name;
  final OptionDisplay display;
  final int sortOrder;
  final List<ProductOptionValue> values;

  const ProductOptionType({
    required this.id,
    this.name = '',
    this.display = OptionDisplay.chip,
    this.sortOrder = 0,
    this.values = const [],
  });

  factory ProductOptionType.fromJson(Map<String, dynamic> j) =>
      ProductOptionType(
        id: j['id'] as int? ?? 0,
        name: (j['name'] ?? '').toString(),
        display: OptionDisplay.from(j['display'] as String?),
        sortOrder: j['sort_order'] as int? ?? 0,
        values: (j['values'] as List<dynamic>? ?? const [])
            .map(
              (v) => ProductOptionValue.fromJson(
                Map<String, dynamic>.from(v as Map),
              ),
            )
            .toList(growable: false),
      );

  @override
  List<Object?> get props => [id, name, display, sortOrder, values];
}

/// A display-ready spec row ("السعة · ٤٠ لترًا"), already localized by the
/// server per `Accept-Language`. Both halves are plain strings — the old
/// `label_ar`/`label_en` pairs are gone (delivery §1.5).
class ProductAttribute extends Equatable {
  final String label;
  final String value;

  const ProductAttribute({this.label = '', this.value = ''});

  /// A row is only worth showing when both halves resolve to something.
  bool get isRenderable => label.isNotEmpty && value.isNotEmpty;

  factory ProductAttribute.fromJson(Map<String, dynamic> j) => ProductAttribute(
    label: (j['label'] ?? '').toString(),
    value: (j['value'] ?? '').toString(),
  );

  static List<ProductAttribute> listFrom(dynamic raw) => raw is List
      ? raw
            .whereType<Map>()
            .map((e) => ProductAttribute.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
      : const [];

  @override
  List<Object?> get props => [label, value];
}
