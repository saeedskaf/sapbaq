/// Customer-app API paths (relative to [Environment.baseUrl]).
///
/// Driver/admin endpoints are intentionally omitted — out of scope.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth — phone OTP + 4-digit passcode + device trust (Sapbaq_AUTH_Flow).
  // Google / Apple sign-in still supported. No passwords.
  // Public (no token):
  static const String otpCheckNumber = '/auth/otp/check-number/';
  static const String otpRequest = '/auth/otp/request/';
  static const String otpVerify = '/auth/otp/verify/';
  static const String socialGoogle = '/auth/social/google/';
  static const String socialApple = '/auth/social/apple/';
  static const String refresh = '/auth/refresh/';
  // Passcode (daily login) — public login/forgot, Bearer set:
  static const String passcodeLogin = '/auth/passcode/login/';
  static const String passcodeSet = '/auth/passcode/set/';
  static const String passcodeForgotRequest = '/auth/passcode/forgot/request/';
  static const String passcodeForgotReset = '/auth/passcode/forgot/reset/';
  // Device trust for a new/unrecognized device (public):
  static const String deviceTrustRequest = '/auth/device/trust/request/';
  static const String deviceTrustVerify = '/auth/device/trust/verify/';
  // Trusted-device management (Bearer): list + revoke.
  static const String deviceTrusted = '/auth/device/trusted/';
  static String deviceTrustedItem(int id) => '/auth/device/trusted/$id/';
  // Authenticated (Bearer):
  static const String phoneRequest = '/auth/phone/request/';
  static const String phoneVerify = '/auth/phone/verify/';
  // The only path that writes a *verified* email — `PATCH /auth/me/` ignores
  // the field by design (FLUTTER_EMAIL_VERIFY_CHANGE_2026-08-19 §5).
  static const String emailRequest = '/auth/email/request/';
  static const String emailVerify = '/auth/email/verify/';
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
  // The gift catalogue endpoints (`/gifts/categories/`, `/gifts/templates/`)
  // were removed server-side: one approved design is picked by the admin and
  // never shown to the donor (GIFT_SIMPLIFIED_2026-08-04 §2).

  // Carts — one cart per destination. All of them check out together into ONE
  // order with one amount and one payment (FLUTTER_COMBINED_CHECKOUT §2).
  // Contract: CARTS_BACKEND_DELIVERY.md.
  static const String carts = '/carts/';
  static const String cartsItems = '/carts/items/';
  static String cartsItem(int id) => '/carts/items/$id/';
  static String cartById(int id) => '/carts/$id/';
  static String cartApplyCoupon(int id) => '/carts/$id/apply-coupon/';
  static String cartCoupon(int id) => '/carts/$id/coupon/';
  static String cartGift(int id) => '/carts/$id/gift/';

  // One checkout for every destination. Omitting `cart_ids` means "all open
  // carts", which is what the pay button wants; passing one id is how a single
  // cart is paid on its own. The per-cart route (`/carts/{id}/checkout/`) still
  // exists server-side and is deliberately unused: two routes for one operation
  // is a fork with nothing on the other side of it.
  static const String cartsCheckout = '/carts/checkout/';

  // «طلباتي» — one feed over product orders, equipment requests and
  // marketplace contributions. No filter parameters by design: the app shows
  // everything in one list (delivery §5).
  static const String activity = '/activity/';

  // Orders & payments
  static const String orders = '/orders/';
  static String order(int id) => '/orders/$id/';
  static String cancelOrder(int id) => '/orders/$id/cancel/';
  static String orderProofs(int id) => '/orders/$id/proofs/';
  static String orderReview(int id) => '/orders/$id/review/';
  static const String initiatePayment = '/payments/initiate/';
  static const String confirmPayment = '/payments/confirm/';

  // Embedded checkout — the card is entered inside the app instead of on the
  // gateway's hosted page. `session` opens the attempt (no gateway invoice
  // yet), `execute` charges it server-side, and `confirm` still decides.
  // KNET and 3-D Secure keep using `initiatePayment` and the hosted page.
  static const String paymentSession = '/payments/session/';
  static const String executePayment = '/payments/execute/';
  static const String savedCards = '/payments/cards/';
  static String savedCard(String token) => '/payments/cards/$token/';
  static const String paymentMethods = '/payments/methods/';

  // Approval-path requests: the donor picks a product + variant from the store,
  // a manager approves, and only then does the payment window open. The old
  // `/equipment-catalog/*` pair is deleted — approval products come from
  // `/products/` like everything else (delivery §3).
  static const String equipmentRequests = '/equipment-requests/';
  static String equipmentRequest(int id) => '/equipment-requests/$id/';
  static String equipmentRequestPay(int id) => '/equipment-requests/$id/pay/';
  static String equipmentRequestCancel(int id) =>
      '/equipment-requests/$id/cancel/';

  // Notifications
  static const String devices = '/notifications/devices/';
  static String device(String token) => '/notifications/devices/$token/';
  static const String notifications = '/notifications/';
  static String notificationRead(int id) => '/notifications/$id/read/';
  static const String notificationsReadAll = '/notifications/read-all/';
  static const String notificationsUnreadCount = '/notifications/unread-count/';

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

  // Mosque-Needs Marketplace (live) — feeds are public; contribute/cancel need
  // Bearer. Contract: MOSQUE_NEEDS_BACKEND_DELIVERY.md.
  static const String marketplaceSummary = '/marketplace/summary/';
  static const String marketplaceWater = '/marketplace/water/';
  static const String marketplaceMaintenance = '/marketplace/maintenance/';
  static const String marketplaceEquipment = '/marketplace/equipment/';
  static const String contributeWater = '/marketplace/contribute/water/';
  static const String contributeMaintenance =
      '/marketplace/contribute/maintenance/';
  static const String contributeContract = '/marketplace/contribute/contract/';
  static const String contributeEquipment =
      '/marketplace/contribute/equipment/';
  static const String contributions = '/marketplace/contributions/';

  /// One contribution with its ready-to-draw status timeline. Owner-only: some
  /// other customer's contribution 404s.
  static String contribution(int id) => '/marketplace/contributions/$id/';
  static String contributionCancel(int id) =>
      '/marketplace/contributions/$id/cancel/';
}
