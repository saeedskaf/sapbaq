/// Centralized route paths and names. Reference these instead of raw strings
/// so navigation stays refactor-safe (e.g. `context.goNamed(AppRoutes.adminOrdersName)`).
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String splashName = 'splash';

  static const String login = '/login';
  static const String loginName = 'login';

  /// Shown when a signed-in account is neither ADMIN nor DRIVER.
  static const String unauthorized = '/unauthorized';
  static const String unauthorizedName = 'unauthorized';

  // --- Admin shell tabs ---
  static const String adminOrders = '/admin/orders';
  static const String adminOrdersName = 'admin-orders';

  static const String adminNotifications = '/admin/notifications';
  static const String adminNotificationsName = 'admin-notifications';

  static const String adminProfile = '/admin/profile';
  static const String adminProfileName = 'admin-profile';

  // Admin full-screen routes (over the shell). Singular `order` to avoid
  // overlapping the `/admin/orders` tab path.
  static const String adminOrderDetail = '/admin/order/:id';
  static const String adminOrderDetailName = 'admin-order-detail';

  static const String adminAssign = '/admin/order/:id/assign';
  static const String adminAssignName = 'admin-assign';

  // --- Driver shell tabs ---
  static const String driverHome = '/driver'; // my deliveries
  static const String driverHomeName = 'driver-home';

  static const String driverNotifications = '/driver/notifications';
  static const String driverNotificationsName = 'driver-notifications';

  static const String driverProfile = '/driver/profile';
  static const String driverProfileName = 'driver-profile';

  // Driver full-screen routes (over the shell).
  static const String driverDestination = '/driver/destination/:id';
  static const String driverDestinationName = 'driver-destination';

  static const String driverProof = '/driver/destination/:id/proof';
  static const String driverProofName = 'driver-proof';
}
