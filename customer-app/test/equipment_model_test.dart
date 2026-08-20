import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq/features/marketplace/data/models/marketplace_models.dart';
import 'package:sapbaq/features/products/data/models/product_option.dart';

/// The campaign variant a funding listing carries after approval: its gallery
/// and the display-ready specs the backend words for us. Both shapes changed in
/// UNIFIED_CATALOG_AND_VARIANTS_BACKEND_DELIVERY (§6.4): the model is now a
/// variant, and specs arrive already localized as `{label, value}`.
void main() {
  group('gallery', () {
    test('parses the gallery as sent, cover first', () {
      final v = ListingVariant.fromJson({
        'id': 12,
        'name': 'حوضان — خشب فاخر',
        'image': 'https://h/cover.png',
        'images': ['https://h/cover.png', 'https://h/side.png'],
      });

      expect(v.gallery, ['https://h/cover.png', 'https://h/side.png']);
      expect(v.gallery.first, v.image);
    });

    test('a response without `images` still has a gallery of one', () {
      final v = ListingVariant.fromJson({
        'id': 1,
        'name': 'X',
        'image': 'https://h/cover.png',
      });

      expect(v.gallery, ['https://h/cover.png']);
    });

    test('a variant with no photo has an empty gallery', () {
      final v = ListingVariant.fromJson({'id': 1, 'name': 'X', 'images': []});

      expect(v.gallery, isEmpty);
    });
  });

  group('display-ready specs', () {
    final v = ListingVariant.fromJson({
      'id': 1,
      'name': 'حوضان — خشب فاخر',
      'attributes_display': [
        {'label': 'عدد الأحواض', 'value': '2'},
        {'label': 'التصميم', 'value': 'فاخر (خشبي)'},
      ],
    });

    test('keeps the backend order and renders the text as sent', () {
      expect(v.attributesDisplay.length, 2);
      expect(v.attributesDisplay.first.label, 'عدد الأحواض');
      expect(v.attributesDisplay.first.value, '2');
      expect(v.attributesDisplay.last.value, 'فاخر (خشبي)');
    });

    test('a half-empty row is not renderable', () {
      const row = ProductAttribute(label: 'التصميم');

      expect(row.isRenderable, isFalse);
    });

    test('a response without the field yields no specs', () {
      final bare = ListingVariant.fromJson({'id': 1, 'name': 'X'});

      expect(bare.attributesDisplay, isEmpty);
    });
  });

  group('listing', () {
    test('is only fundable once a variant and a goal are published', () {
      final listing = EquipmentListing.fromJson({
        'request_id': 3,
        'mosque': {'id': 7, 'name': 'مسجد النور'},
        'equipment_type': 'مبرّد ماء',
        'equipment_type_id': 1,
      });

      expect(listing.isFundable, isFalse);
    });

    test('titles itself from the product plus the chosen combination', () {
      final listing = EquipmentListing.fromJson({
        'request_id': 3,
        'mosque': {'id': 7, 'name': 'مسجد النور'},
        'equipment_type': 'مبرّد ماء',
        'equipment_type_id': 1,
        'product': {'id': 508, 'name': 'مبرّد مياه ستيل'},
        'variant': {'id': 9101, 'name': 'حوضان — عادي'},
        'funding': {'target_amount': '145.00', 'remaining': '85.00'},
      });

      expect(listing.isFundable, isTrue);
      expect(listing.title, 'مبرّد مياه ستيل — حوضان — عادي');
    });
  });
}
