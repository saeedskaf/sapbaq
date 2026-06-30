/// Centralized route paths and names. Reference these instead of raw strings
/// so navigation stays refactor-safe (e.g. `context.goNamed(AppRoutes.adminOrdersName)`).
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String splashName = 'splash';

  static const String login = '/login';
  static const String loginName = 'login';

  /// Shown when a signed-in account isn't a staff role (customer, MOSQUE_REP).
  static const String unauthorized = '/unauthorized';
  static const String unauthorizedName = 'unauthorized';

  // --- Admin shell tabs ---
  static const String adminDashboard = '/admin/dashboard';
  static const String adminDashboardName = 'admin-dashboard';

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

  static const String adminActivity = '/admin/activity';
  static const String adminActivityName = 'admin-activity';

  static const String adminCustomerLookup = '/admin/customers';
  static const String adminCustomerLookupName = 'admin-customer-lookup';

  static const String adminApprovals = '/admin/approvals';
  static const String adminApprovalsName = 'admin-approvals';

  static const String adminEscalations = '/admin/escalations';
  static const String adminEscalationsName = 'admin-escalations';

  static const String adminProducts = '/admin/products';
  static const String adminProductsName = 'admin-products';

  // --- Retail-operator shell tabs (LV3: customer search + profile only) ---
  static const String retailCustomers = '/retail/customers';
  static const String retailCustomersName = 'retail-customers';

  static const String retailProfile = '/retail/profile';
  static const String retailProfileName = 'retail-profile';

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
