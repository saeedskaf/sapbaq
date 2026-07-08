/// Customer-app API paths (relative to [Environment.baseUrl]).
///
/// Driver/admin endpoints are intentionally omitted — out of scope.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth — passwordless (Google / Apple / phone OTP). No passwords.
  // Public (no token):
  static const String otpRequest = '/auth/otp/request/';
  static const String otpVerify = '/auth/otp/verify/';
  static const String socialGoogle = '/auth/social/google/';
  static const String socialApple = '/auth/social/apple/';
  static const String refresh = '/auth/refresh/';
  // Authenticated (Bearer):
  static const String phoneRequest = '/auth/phone/request/';
  static const String phoneVerify = '/auth/phone/verify/';
  static const String profileComplete = '/auth/profile/complete/';
  static const String me = '/auth/me/';
  // Passkeys (WebAuthn). Login begin/complete are public; the rest need a token.
  static const String passkeyRegisterBegin = '/auth/passkey/register/begin/';
  static const String passkeyRegisterComplete =
      '/auth/passkey/register/complete/';
  static const String passkeyLoginBegin = '/auth/passkey/login/begin/';
  static const String passkeyLoginComplete = '/auth/passkey/login/complete/';
  static const String passkeyDevices = '/auth/passkey/devices/';
  static String passkeyDevice(int id) => '/auth/passkey/devices/$id/';

  // Browse
  static const String banners = '/banners/';
  static const String showcase = '/showcase/'; // public media gallery
  static const String showcaseSections =
      '/showcase/sections/'; // gallery grouped by section
  static const String mosques = '/mosques/';
  static const String mosquesMap = '/mosques/map/';
  static String mosque(int id) => '/mosques/$id/';
  static const String products = '/products/';
  static String product(int id) => '/products/$id/';
  static const String productCategories = '/products/categories/';
  static String productsByCategory(int id) =>
      '/products/categories/$id/products/';
  static const String activeCoupons = '/coupons/active/';
  static const String validateCoupon = '/coupons/validate/';
  static const String giftTemplates = '/gifts/templates/';
  static const String giftCategories = '/gifts/categories/';
  static String giftCategoryTemplates(int id) =>
      '/gifts/categories/$id/templates/';

  // Cart
  static const String cart = '/cart/';
  static const String cartItems = '/cart/items/';
  static String cartItem(int id) => '/cart/items/$id/';
  static String cartGroup(int id) => '/cart/groups/$id/';
  static const String applyCoupon = '/cart/apply-coupon/';
  static const String cartCoupon = '/cart/coupon/';
  static const String cartGift = '/cart/gift/';
  static const String checkout = '/cart/checkout/';

  // Orders & payments
  static const String orders = '/orders/';
  static String order(int id) => '/orders/$id/';
  static String cancelOrder(int id) => '/orders/$id/cancel/';
  static String orderProofs(int id) => '/orders/$id/proofs/';
  static String orderReview(int id) => '/orders/$id/review/';
  static const String initiatePayment = '/payments/initiate/';
  static const String confirmPayment = '/payments/confirm/';

  // Notifications
  static const String devices = '/notifications/devices/';
  static String device(String token) => '/notifications/devices/$token/';
  static const String notifications = '/notifications/';

  // Notification preferences (A.3)
  static const String notificationPreferences = '/notifications/preferences/';

  // Saved addresses (A.3) — per-user CRUD
  static const String addresses = '/addresses/';
  static String address(int id) => '/addresses/$id/';

  // Favorite mosques (A.3)
  static const String mosqueFavorites = '/mosques/favorites/';
  static String mosqueFavorite(int mosqueId) => '/mosques/favorites/$mosqueId/';

  // CMS content pages (A.3): privacy | terms | about | faq
  static String content(String slug) => '/content/$slug/';

  // Structured support-contact details for the "Contact us" screen.
  static const String contact = '/content/contact/';

  // Support tickets (A.3)
  static const String supportTickets = '/support/tickets/';
  static const String supportUnreadCount = '/support/tickets/unread-count/';
  static String supportTicket(int id) => '/support/tickets/$id/';
  static String supportTicketMessages(int id) =>
      '/support/tickets/$id/messages/';
  static String supportTicketRead(int id) => '/support/tickets/$id/read/';

  // Mosque filter facets — cascading governorate/area/block
  static const String mosquesFilters = '/mosques/filters/';
}
