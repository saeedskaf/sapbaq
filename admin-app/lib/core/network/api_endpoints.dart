/// Admin & Driver app API paths (relative to [Environment.baseUrl]).
///
/// Same backend and conventions as the customer app. Only the cross-cutting
/// auth + notifications endpoints are defined for now; admin- and
/// driver-specific endpoints are added under the placeholder section below as
/// those features are built.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth — shared with the customer app; `user_type` distinguishes the role.
  static const String signup = '/auth/signup/';
  static const String verifyOtp = '/auth/verify-otp/';
  static const String login = '/auth/login/';
  static const String forgotPassword = '/auth/forgot-password/';
  static const String resetPassword = '/auth/reset-password/';
  static const String refresh = '/auth/refresh/';
  static const String me = '/auth/me/';

  // Notifications — push device registration + inbox (cross-cutting).
  static const String devices = '/notifications/devices/';
  static String device(String token) => '/notifications/devices/$token/';
  static const String notifications = '/notifications/';
  static String notificationRead(int id) => '/notifications/$id/read/';
  static const String notificationsReadAll = '/notifications/read-all/';
  static const String notificationsUnreadCount = '/notifications/unread-count/';

  // Mosques — shared browse endpoint, used by admin to pick a mosque when
  // assigning a "most-needed" destination, and by rep self-registration
  // (governorate → area → mosque cascade).
  static const String mosques = '/mosques/';
  static const String mosquesFilters = '/mosques/filters/';

  // --- Mosque representative (الإمام) — ADMIN_APP_BACKEND_INTEGRATION §1 ---
  // Public (no token):
  static const String repOtpRequest = '/rep/otp/request/';
  static const String repRegister = '/rep/register/';
  static String repInvite(String token) => '/rep/invite/$token/';
  static const String repRegisterInvite = '/rep/register-invite/';
  static const String repLogin = '/rep/login/';
  static const String repResetPasscode = '/rep/reset-passcode/';
  // Bearer (MOSQUE_REP):
  static const String repMe = '/rep/me/';
  static const String repEquipment = '/rep/equipment/';
  static const String repMaintenance = '/rep/maintenance/';
  static const String repWaterFlag = '/rep/water-flag/';
  static const String repEquipmentRequest = '/rep/equipment-request/';

  /// Equipment-type catalogue for the rep's new-equipment request.
  /// ⚠️ Proposed to backend (Gap C in ADMIN_MODULES_FRONTEND_PLAN) — the form
  /// surfaces the server error until it ships.
  static const String repEquipmentTypes = '/rep/equipment-types/';

  // --- Admin ---
  static const String adminOrders = '/admin/orders/';
  static const String adminOrdersCounts = '/admin/orders/counts/';
  static String adminOrder(int id) => '/admin/orders/$id/';
  static String adminReassignOrder(int id) => '/admin/orders/$id/reassign/';
  static String adminCancelOrder(int id) => '/admin/orders/$id/cancel/';
  static const String adminWorkshops = '/admin/workshops/';

  // Two-level assignment (FLUTTER_TASKS T3): a manager assigns the order to a
  // team leader, who then distributes each destination to a handler (workshop)
  // or approves its completion directly.
  static const String adminTeamLeaders = '/admin/team-leaders/';
  static String adminAssignTeam(int id) => '/admin/orders/$id/assign-team/';
  static String adminAssignHandler(int id) =>
      '/admin/orders/$id/assign-handler/';
  static String adminCompleteOrder(int id) => '/admin/orders/$id/complete/';
  static const String adminDashboard = '/admin/me/dashboard/';
  static const String adminActivity = '/admin/me/activity/';
  static const String adminCustomerLookup = '/admin/customers/lookup/';

  static const String adminApprovals = '/admin/approvals/';
  static String adminApproveApproval(int id) => '/admin/approvals/$id/approve/';
  static String adminRejectApproval(int id) => '/admin/approvals/$id/reject/';

  static const String adminEscalations = '/admin/escalations/';
  static String adminResolveEscalation(int id) =>
      '/admin/escalations/$id/resolve/';

  static const String adminProducts = '/admin/products/';
  static String adminProductAvailability(int id) =>
      '/admin/products/$id/availability/';

  // --- Manager direct provision (FLUTTER_MANAGER_DIRECT_PROVISION) ---
  // A regional/global manager raises a water/equipment/maintenance need for a
  // mosque they pick, and it is created already APPROVED (no approval step).

  /// Role-scoped mosque list for the manager's mosque picker: the regional
  /// manager gets his governorate, the global admin gets all. Distinct from the
  /// public [mosques] browse endpoint, which isn't scoped — picking outside the
  /// manager's governorate there would only fail with 403 on submit.
  static const String adminMosques = '/admin/mosques/';

  /// Equipment-type catalogue for the direct equipment request, and the
  /// products of a type with their option axes and variants. The manager must
  /// pick a variant at creation time because the request publishes to the
  /// marketplace immediately (it needs a target amount).
  ///
  /// `/admin/equipment-models/` was deleted with the unified catalogue —
  /// `equipment-options/` replaces it and returns whole products
  /// (UNIFIED_CATALOG_AND_VARIANTS_BACKEND_DELIVERY §6.3).
  static const String adminEquipmentTypes = '/admin/equipment-types/';
  static const String adminEquipmentOptions = '/admin/equipment-options/';

  /// The units installed at a mosque, for the direct maintenance report's unit
  /// picker. `?mosque_id=` is required — out of scope or missing gives `[]`.
  static const String adminMaintenanceEquipment =
      '/admin/maintenance-equipment/';

  // Water-flags moderation (ADMIN_APP_BACKEND_INTEGRATION §2).
  // `POST` on this same collection is the manager's direct water flag.
  static const String adminWaterFlags = '/admin/water-flags/';
  static String adminWaterFlagApprove(int id) =>
      '/admin/water-flags/$id/approve/';
  static String adminWaterFlagCancel(int id) =>
      '/admin/water-flags/$id/cancel/';

  // Equipment-requests moderation (§3) — approved by the regional manager.
  static const String adminEquipmentRequests = '/admin/equipment-requests/';

  /// Approving publishes the campaign, so it carries the picked product and
  /// variant — that choice is what freezes the funding goal.
  ///
  /// Stays under `/admin/` deliberately: that is where the regional-manager
  /// permission and the governorate scoping live, alongside `reject/`,
  /// `cancel/` and the direct-provision `POST`. Approving is an administrative
  /// **write**; only the options lookup is a public read
  /// (BACKEND_ANSWERS_STAFF_ENDPOINTS_2026-08-04 §تأكيد ١).
  static String adminEquipmentRequestApprove(int id) =>
      '/admin/equipment-requests/$id/approve/';

  /// The products this request's equipment type can be fulfilled with, each
  /// with its axes and variants — the same serializer the customer app reads,
  /// so there is no third shape to learn. Keyed by the request, so it needs no
  /// `equipment_type_id` (the request rows don't carry one).
  static String marketplaceEquipmentOptions(int requestId) =>
      '/marketplace/equipment/$requestId/options/';
  static String adminEquipmentRequestReject(int id) =>
      '/admin/equipment-requests/$id/reject/';
  static String adminEquipmentRequestCancel(int id) =>
      '/admin/equipment-requests/$id/cancel/';

  // Catalogue equipment orders (FLUTTER_NONLIVE_EQUIPMENT_ORDERING §ثانياً) —
  // a customer's purchase of a specific unit for a mosque, which a manager
  // approves before the payment window opens. Distinct from
  // [adminEquipmentRequests], which is the imam asking donors to fund a unit.
  static const String adminCatalogOrders = '/admin/equipment-requests-catalog/';
  static String adminCatalogOrder(int id) =>
      '/admin/equipment-requests-catalog/$id/';
  static String adminCatalogOrderAction(int id, String action) =>
      '/admin/equipment-requests-catalog/$id/$action/';

  // Operations-center workload — one role-scoped endpoint returning the
  // "needs my action" count per queue (FLUTTER_OPERATIONS_CENTER / backend
  // reply §2). Replaces counting via four separate list calls.
  static const String adminOpsCounts = '/admin/ops/counts/';

  // Maintenance triage & dispatch (§4).
  static const String adminMaintenance = '/admin/maintenance/';
  static String adminMaintenanceCase(int id) => '/admin/maintenance/$id/';
  static String adminMaintenanceAction(int id, String action) =>
      '/admin/maintenance/$id/$action/';

  /// Contribution amounts/states, view-only — the old per-contribution
  /// `fulfil/` action was removed; field work now runs on fulfilment tasks
  /// (BACKEND_CHANGES_UNIFIED_FULFILMENT_DISPATCH §0).
  static const String adminContributions = '/admin/marketplace/contributions/';

  // Unified fulfilment dispatch (§1): a task queue with a two-level assignment
  // chain. Actions: assign-team-leader · assign-handler · fulfil (multipart
  // `statement` + `photo`).
  static const String adminFulfilmentTasks =
      '/admin/marketplace/fulfilment-tasks/';
  static String adminFulfilmentTaskAction(int id, String action) =>
      '/admin/marketplace/fulfilment-tasks/$id/$action/';

  // --- Driver (workshop) ---
  static const String driverDestinations = '/orders/driver/destinations/';
  static String driverDestination(int id) => '/orders/driver/destinations/$id/';
  static String driverAccept(int id) =>
      '/orders/driver/destinations/$id/accept/';
  static String driverReject(int id) =>
      '/orders/driver/destinations/$id/reject/';
  static String driverStartDelivery(int id) =>
      '/orders/driver/destinations/$id/start-delivery/';

  /// Upload a delivery proof (multipart) — shared destination route, not under
  /// the `/driver/` prefix.
  static String uploadProof(int destinationId) =>
      '/orders/destinations/$destinationId/upload-proof/';
}
