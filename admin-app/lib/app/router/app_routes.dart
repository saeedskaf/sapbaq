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

  // --- Settings (reachable from every role's profile) ---
  static const String settingsLanguage = '/settings/language';
  static const String settingsLanguageName = 'settings-language';

  static const String settingsAppearance = '/settings/appearance';
  static const String settingsAppearanceName = 'settings-appearance';

  // --- Admin shell tabs ---
  static const String adminDashboard = '/admin/dashboard';
  static const String adminDashboardName = 'admin-dashboard';

  /// The operations center as an admin-shell tab. Distinct from [opsHub]
  /// (the same screen pushed over any shell) and from the retail/driver
  /// shells' own tabs ([retailOperations], [driverOperations]).
  static const String adminOperations = '/admin/operations';
  static const String adminOperationsName = 'admin-operations';

  static const String adminOrders = '/admin/orders';
  static const String adminOrdersName = 'admin-orders';

  /// A dashboard stat tile opens the list already filtered to the bucket it
  /// counts, via `?tab=<AdminOrdersTab.name>`. Internal deep-link only — no
  /// backend payload carries it, so the enum name is the contract.
  static const String adminOrdersTabQuery = 'tab';

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

  // --- Retail-operator shell tabs (LV3: customer search + operations +
  // profile) ---
  static const String retailCustomers = '/retail/customers';
  static const String retailCustomersName = 'retail-customers';

  static const String retailOperations = '/retail/operations';
  static const String retailOperationsName = 'retail-operations';

  static const String retailProfile = '/retail/profile';
  static const String retailProfileName = 'retail-profile';

  // --- Driver shell tabs ---
  static const String driverHome = '/driver'; // my deliveries
  static const String driverHomeName = 'driver-home';

  static const String driverOperations = '/driver/operations';
  static const String driverOperationsName = 'driver-operations';

  static const String driverNotifications = '/driver/notifications';
  static const String driverNotificationsName = 'driver-notifications';

  static const String driverProfile = '/driver/profile';
  static const String driverProfileName = 'driver-profile';

  // Driver full-screen routes (over the shell).
  static const String driverDestination = '/driver/destination/:id';
  static const String driverDestinationName = 'driver-destination';

  static const String driverProof = '/driver/destination/:id/proof';
  static const String driverProofName = 'driver-proof';

  // --- Mosque representative (الإمام) — auth flow (public) ---
  // --- Operations center (staff moderation hub — neutral prefix so every
  // staff role reaches it, rep excluded). Every staff shell now carries the
  // hub as a tab; `/ops` stays as the shell-agnostic pushed/deep-link entry.
  static const String opsHub = '/ops';
  static const String opsHubName = 'ops-hub';

  static const String opsWaterFlags = '/ops/water-flags';
  static const String opsWaterFlagsName = 'ops-water-flags';

  static const String opsEquipmentRequests = '/ops/equipment-requests';
  static const String opsEquipmentRequestsName = 'ops-equipment-requests';

  static const String opsMaintenance = '/ops/maintenance';
  static const String opsMaintenanceName = 'ops-maintenance';

  static const String opsMaintenanceDetail = '/ops/maintenance/:id';
  static const String opsMaintenanceDetailName = 'ops-maintenance-detail';

  static const String opsContributions = '/ops/contributions';
  static const String opsContributionsName = 'ops-contributions';

  static const String opsFulfilmentTasks = '/ops/fulfilment-tasks';
  static const String opsFulfilmentTasksName = 'ops-fulfilment-tasks';

  /// Catalogue equipment orders (customer purchases awaiting approval and
  /// installation) — distinct from [opsEquipmentRequests], the imam's requests.
  static const String opsCatalogOrders = '/ops/catalog-orders';
  static const String opsCatalogOrdersName = 'ops-catalog-orders';

  // Manager direct provision (REGIONAL_MANAGER / GLOBAL_ADMIN only): raise a
  // need for a chosen mosque, created already approved.
  static const String opsDirect = '/ops/direct';
  static const String opsDirectName = 'ops-direct';

  static const String opsDirectWater = '/ops/direct/water';
  static const String opsDirectWaterName = 'ops-direct-water';

  static const String opsDirectEquipment = '/ops/direct/equipment';
  static const String opsDirectEquipmentName = 'ops-direct-equipment';

  static const String opsDirectMaintenance = '/ops/direct/maintenance';
  static const String opsDirectMaintenanceName = 'ops-direct-maintenance';

  static const String repLogin = '/rep-auth/login';
  static const String repLoginName = 'rep-login';

  static const String repPasscode = '/rep-auth/passcode';
  static const String repPasscodeName = 'rep-passcode';

  static const String repRegister = '/rep-auth/register';
  static const String repRegisterName = 'rep-register';

  static const String repInvite = '/rep-auth/invite';
  static const String repInviteName = 'rep-invite';

  static const String repForgot = '/rep-auth/forgot';
  static const String repForgotName = 'rep-forgot';

  static const String repPending = '/rep-auth/pending';
  static const String repPendingName = 'rep-pending';

  // --- Mosque representative shell tabs ---
  static const String repMosque = '/rep';
  static const String repMosqueName = 'rep-mosque';

  static const String repReports = '/rep/reports';
  static const String repReportsName = 'rep-reports';

  // «بلاغاتي» has one tab per need type. A notification points at a specific
  // row, so it opens the tab holding it via `?tab=maintenance|water|equipment`.
  static const String repReportsTabQuery = 'tab';
  static const String repReportsTabMaintenance = 'maintenance';
  static const String repReportsTabWater = 'water';
  static const String repReportsTabEquipment = 'equipment';

  static const String repNotifications = '/rep/notifications';
  static const String repNotificationsName = 'rep-notifications';

  static const String repProfile = '/rep/profile';
  static const String repProfileName = 'rep-profile';

  // Rep full-screen routes (over the shell).
  static const String repReportForm = '/rep/report-form';
  static const String repReportFormName = 'rep-report-form';

  static const String repEquipmentForm = '/rep/equipment-form';
  static const String repEquipmentFormName = 'rep-equipment-form';
}
