import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq_admin/features/notifications/data/models/app_notification.dart';

/// The inbox row's bilingual copy: the backend localizes `title`/`body` per the
/// request's Accept-Language and ships both languages alongside, so switching
/// language re-renders a loaded list without a refetch.
void main() {
  test('picks the copy for the requested language', () {
    final n = AppNotification.fromJson({
      'id': 812,
      'notification_type': 'order.delivered',
      'title': 'Your order has been delivered',
      'body': 'Order ORD-00042 was delivered successfully.',
      'title_ar': 'تم توصيل طلبك',
      'title_en': 'Your order has been delivered',
      'body_ar': 'تم تسليم الطلب ORD-00042 بنجاح.',
      'body_en': 'Order ORD-00042 was delivered successfully.',
      'data': {'order_id': 42},
      'created_at': '2026-07-15T09:12:44Z',
    });

    expect(n.titleFor('ar'), 'تم توصيل طلبك');
    expect(n.titleFor('en'), 'Your order has been delivered');
    expect(n.bodyFor('ar'), 'تم تسليم الطلب ORD-00042 بنجاح.');
    expect(n.orderId, 42);
  });

  test('falls back to the server copy for a row stored in one language', () {
    // Rows sent before the backend stored both languages (§A.3 item 4).
    final n = AppNotification.fromJson({
      'id': 1,
      'notification_type': 'order.confirmed',
      'title': 'تم تأكيد طلبك',
      'body': 'الطلب ORD-1',
      'data': {'order_id': 1},
    });

    expect(n.titleFor('en'), 'تم تأكيد طلبك');
    expect(n.bodyFor('en'), 'الطلب ORD-1');
  });

  test('falls back to the other language rather than rendering blank', () {
    final n = AppNotification.fromJson({
      'id': 2,
      'notification_type': 'order.confirmed',
      'title': '',
      'body': '',
      'title_ar': 'تم تأكيد طلبك',
      'body_ar': 'الطلب ORD-1',
    });

    expect(n.titleFor('en'), 'تم تأكيد طلبك');
    expect(n.bodyFor('en'), 'الطلب ORD-1');
  });
}
