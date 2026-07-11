/// Centralized route paths and names. Reference these instead of raw strings
/// so navigation stays refactor-safe (e.g. `context.goNamed(AppRoutes.homeName)`).
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String splashName = 'splash';

  static const String login = '/login';
  static const String loginName = 'login';

  static const String otp = '/otp';
  static const String otpName = 'otp';

  // Returning sign-in: enter the 4-digit passcode (registered + passcode set).
  static const String passcodeLogin = '/passcode';
  static const String passcodeLoginName = 'passcode-login';

  // New/unrecognized device (428): OTP to establish device trust.
  static const String deviceTrust = '/device-trust';
  static const String deviceTrustName = 'device-trust';

  // Passcode recovery (forgot / locked): OTP then a new passcode.
  static const String forgotPasscode = '/forgot-passcode';
  static const String forgotPasscodeName = 'forgot-passcode';

  // App-entry unlock for a persisted session (biometric or passcode).
  static const String lock = '/lock';
  static const String lockName = 'lock';

  // First-use onboarding for a fresh account (needs_profile). A social user with
  // no phone verifies one here; everyone then completes name/email.
  static const String verifyPhone = '/verify-phone';
  static const String verifyPhoneName = 'verify-phone';

  static const String completeProfile = '/complete-profile';
  static const String completeProfileName = 'complete-profile';

  // Set the 4-digit passcode (end of onboarding), then opt into biometrics.
  static const String setPasscode = '/set-passcode';
  static const String setPasscodeName = 'set-passcode';

  // --- Authenticated shell tabs ---
  static const String home = '/'; // Donation entry (Home tab)
  static const String homeName = 'home';

  // Products for a chosen destination — full-screen; destination via `extra`.
  static const String products = '/products';
  static const String productsName = 'products';

  // Product detail — full-screen over the shell. The path carries the product
  // id; `extra` carries the active DonationDestination so "add to cart" knows
  // which group to attach to.
  static const String productDetail = '/product/:id';
  static const String productDetailName = 'product-detail';

  static const String mosques = '/mosques';
  static const String mosquesName = 'mosques';

  // Mosque detail — full-screen over the shell.
  static const String mosqueDetail = '/mosque/:id';
  static const String mosqueDetailName = 'mosque-detail';

  static const String cart = '/cart';
  static const String cartName = 'cart';

  static const String media = '/media';
  static const String mediaName = 'media';

  static const String orders = '/orders';
  static const String ordersName = 'orders';

  // Order detail — full-screen over the shell.
  static const String orderDetail = '/order/:id';
  static const String orderDetailName = 'order-detail';

  static const String profile = '/profile';
  static const String profileName = 'profile';

  // Cart flow — full-screen over the shell.
  static const String checkout = '/checkout';
  static const String checkoutName = 'checkout';
  static const String orderSuccess = '/order-success';
  static const String orderSuccessName = 'order-success';

  // Gift (إهداء) form — full-screen over the shell; existing gift via `extra`.
  static const String giftForm = '/gift';
  static const String giftFormName = 'gift-form';

  // Notifications inbox — full-screen over the shell (opened from home bell).
  static const String notifications = '/notifications';
  static const String notificationsName = 'notifications';

  // Static info pages — full-screen over the shell (opened from Profile).
  static const String about = '/about';
  static const String aboutName = 'about';
  static const String contact = '/contact';
  static const String contactName = 'contact';
  static const String privacy = '/privacy';
  static const String privacyName = 'privacy';
  static const String terms = '/terms';
  static const String termsName = 'terms';
  static const String faq = '/faq';
  static const String faqName = 'faq';

  // Settings — full-screen over the shell (opened from Profile).
  static const String appearance = '/appearance';
  static const String appearanceName = 'appearance';
  static const String language = '/language';
  static const String languageName = 'language';
  static const String notificationPrefs = '/notification-preferences';
  static const String notificationPrefsName = 'notification-preferences';

  // Saved addresses (A.3) — list + add/edit form.
  static const String addresses = '/addresses';
  static const String addressesName = 'addresses';
  static const String addressForm = '/address-form';
  static const String addressFormName = 'address-form';

  // Favorite mosques (A.3).
  static const String favorites = '/favorites';
  static const String favoritesName = 'favorites';

  // Trusted-device management (from Profile → account).
  static const String trustedDevices = '/trusted-devices';
  static const String trustedDevicesName = 'trusted-devices';

  // Support tickets (A.3).
  static const String support = '/support';
  static const String supportName = 'support';
  static const String newTicket = '/new-ticket';
  static const String newTicketName = 'new-ticket';
  static const String ticketDetail = '/ticket/:id';
  static const String ticketDetailName = 'ticket-detail';
}
