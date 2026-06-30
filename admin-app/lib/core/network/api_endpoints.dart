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

  // Mosques — shared browse endpoint, used by admin to pick a mosque when
  // assigning a "most-needed" destination.
  static const String mosques = '/mosques/';

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

  // --- Driver (workshop) ---
  static const String driverDestinations = '/orders/driver/destinations/';
  static String driverDestination(int id) =>
      '/orders/driver/destinations/$id/';
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
