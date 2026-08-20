import 'package:equatable/equatable.dart';

/// A lightweight reference to another staff user (e.g. the current user's
/// direct manager), as embedded in `GET /auth/me/`.
class StaffRef extends Equatable {
  final int id;
  final String fullName;
  final String phone;
  final String userType;

  const StaffRef({
    required this.id,
    required this.fullName,
    this.phone = '',
    this.userType = '',
  });

  factory StaffRef.fromJson(Map<String, dynamic> json) => StaffRef(
    id: json['id'] as int? ?? 0,
    fullName: (json['full_name'] ?? '').toString(),
    phone: (json['phone'] ?? '').toString(),
    userType: (json['user_type'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
    'user_type': userType,
  };

  @override
  List<Object?> get props => [id, fullName, phone, userType];
}

/// The governorate a staff member is scoped to (regional roles). Geographic
/// names stay Arabic; `name_en` is omitted here since the app is Arabic-only.
class Governorate extends Equatable {
  final int id;
  final String code;
  final String name;

  const Governorate({required this.id, this.code = '', this.name = ''});

  factory Governorate.fromJson(Map<String, dynamic> json) => Governorate(
    id: json['id'] as int? ?? 0,
    code: (json['code'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {'id': id, 'code': code, 'name': name};

  @override
  List<Object?> get props => [id, code, name];
}

/// An authenticated staff user (`GET /auth/me/`).
///
/// `userType` is one of seven staff roles (see STAFF_APP_API_HANDOFF §1). It
/// drives which area of the app the user lands in: office/back-office roles →
/// admin shell, `SERVICE_HANDLER` (the workshop) → driver shell. `MOSQUE_REP`
/// is reserved (not staff yet) and customers are rejected entirely.
class User extends Equatable {
  final int id;
  final String phone;
  final String fullName;
  final String email;
  final String userType;

  /// Server-localized role label (e.g. "مدير إقليمي"). Display as-is.
  final String roleDisplay;

  /// 1 (lowest) … 6 (highest). May be 0 on the slim login payload; use [level].
  final int roleLevel;

  final Governorate? governorate;
  final StaffRef? manager;
  final bool isPhoneVerified;
  final String? dateJoined;

  const User({
    required this.id,
    required this.phone,
    required this.fullName,
    this.email = '',
    this.userType = 'CUSTOMER',
    this.roleDisplay = '',
    this.roleLevel = 0,
    this.governorate,
    this.manager,
    this.isPhoneVerified = false,
    this.dateJoined,
  });

  // --- Role identity (STAFF_APP_API_HANDOFF §1) ---
  static const String globalAdmin = 'GLOBAL_ADMIN';
  static const String regionalManager = 'REGIONAL_MANAGER';
  static const String supportAdmin = 'SUPPORT_ADMIN';
  static const String retailOperator = 'RETAIL_OPERATOR';
  static const String teamLeader = 'TEAM_LEADER';
  static const String serviceHandler = 'SERVICE_HANDLER';
  static const String mosqueRep = 'MOSQUE_REP';

  bool get isGlobalAdmin => userType == globalAdmin || userType == 'ADMIN';

  /// Office/back-office roles that land in the admin shell. The legacy `ADMIN`
  /// type is kept for backward compatibility with older tokens.
  bool get isOfficeStaff =>
      userType == globalAdmin ||
      userType == regionalManager ||
      userType == supportAdmin ||
      userType == retailOperator ||
      userType == teamLeader ||
      userType == 'ADMIN';

  /// The workshop/field role that lands in the driver shell (legacy `DRIVER`).
  bool get isServiceHandler =>
      userType == serviceHandler || userType == 'DRIVER';

  /// The retail operator (LV3) — a back-office role whose app is restricted to
  /// the customer-search + profile shell. Everything else is empty/403 for it
  /// on the backend, so we hide those screens (FLUTTER_TASKS T1).
  bool get isRetailOperator => userType == retailOperator;

  /// The mosque representative (الإمام) — report-only, scoped to his mosque,
  /// landing in the rep shell (ADMIN_APP_BACKEND_INTEGRATION §1).
  bool get isMosqueRep => userType == mosqueRep;

  /// Whether this account may use the staff areas of the app.
  bool get isStaff => isOfficeStaff || isServiceHandler;

  // Legacy aliases — existing call sites (router, notifications) read these.
  bool get isAdmin => isOfficeStaff;
  bool get isDriver => isServiceHandler;

  /// Effective role level 1..6, falling back to a per-type default when the
  /// backend omits `role_level` (e.g. on the slim login response).
  int get level => roleLevel > 0 ? roleLevel : _defaultLevel;

  int get _defaultLevel {
    switch (userType) {
      case globalAdmin:
      case 'ADMIN':
        return 6;
      case regionalManager:
        return 5;
      case supportAdmin:
        return 4;
      case retailOperator:
        return 3;
      case teamLeader:
        return 2;
      case serviceHandler:
      case 'DRIVER':
        return 1;
      default:
        return 0;
    }
  }

  // --- Default permission matrix (STAFF_APP_API_HANDOFF §13) ---
  // UI hints ONLY. The server is authoritative (returns 403 if denied), the
  // matrix is editable per role from the admin web, and delegation (§12) can
  // grant temporary permissions. Treat "button shown" as a guess, not a fact.
  bool get canAssignOrders =>
      isGlobalAdmin || userType == regionalManager || userType == supportAdmin;

  /// Team leaders distribute a team-assigned destination to a handler or
  /// approve its completion themselves (FLUTTER_TASKS T3).
  bool get canDispatchTeam => isGlobalAdmin || userType == teamLeader;
  bool get canReassignOrders =>
      isGlobalAdmin || userType == regionalManager || userType == supportAdmin;
  bool get canCancelOrders => isGlobalAdmin || userType == regionalManager;
  bool get canSuspendProductAvailability =>
      isGlobalAdmin || userType == regionalManager;
  bool get canLookupCustomerHistory =>
      isGlobalAdmin || userType == retailOperator;
  bool get canViewTeamHistory => isGlobalAdmin || userType == teamLeader;
  bool get canViewRegionalHistory =>
      isGlobalAdmin || userType == regionalManager;

  // --- Mosque-needs & maintenance moderation (ADMIN_APP_ADDITIONS_BY_ROLE §2) ---
  /// The dispatch desk (retail operator + support admin, plus the global admin):
  /// triages maintenance and cancels equipment. Maintenance triage stays desk-
  /// only; water-flag moderation now includes the regional manager (below).
  bool get isDispatchDesk =>
      isGlobalAdmin || userType == retailOperator || userType == supportAdmin;

  /// Approve/cancel water flags: the dispatch desk, plus the regional manager
  /// for his own governorate (server-scoped) — FLUTTER_OPERATIONS_CENTER §3.3.
  bool get canModerateWaterFlags =>
      isDispatchDesk || userType == regionalManager;

  /// Maintenance desk actions (acknowledge/set-priority/approve/assign-leader/
  /// duplicate/cancel): the dispatch desk, plus the regional manager within
  /// his governorate — unified-dispatch doc §4-b (out-of-scope cases 404).
  bool get canTriageMaintenance =>
      isDispatchDesk || userType == regionalManager;

  /// Any staff role touches maintenance (the server scopes the list): the desk
  /// triages, the regional manager views his governorate, the team leader his
  /// team, the service handler his own assignments.
  bool get canAccessMaintenance => isStaff;

  /// Equipment requests: approved/rejected by the regional manager for his
  /// governorate; the dispatch desk may only cancel.
  bool get canApproveEquipment => isGlobalAdmin || userType == regionalManager;
  bool get canCancelEquipment => isDispatchDesk;

  /// The dispatch chain that works the marketplace fulfilment-task queue
  /// (unified-dispatch doc §1/§5): the desk assigns leaders, leaders assign
  /// handlers, handlers/leaders fulfil, and the regional manager does all of
  /// it within his governorate. Gates the queue's entry points.
  bool get canFulfilContribution =>
      isDispatchDesk ||
      userType == regionalManager ||
      userType == teamLeader ||
      isServiceHandler;

  /// Assign a fulfilment task to a team leader: the dispatch desk plus the
  /// regional manager (server-scoped to his governorate).
  bool get canAssignTaskLeader => isDispatchDesk || userType == regionalManager;

  /// Override the task's assignment chain — assign a handler past the leader,
  /// or fulfil a task that isn't one's own (unified-dispatch doc §5).
  bool get canBypassTaskChain => isGlobalAdmin || userType == regionalManager;

  // --- Manager direct provision (FLUTTER_MANAGER_DIRECT_PROVISION) ---

  /// Raise a water/equipment/maintenance need for a chosen mosque, published
  /// immediately with no approval step: the regional manager within his
  /// governorate, the global admin anywhere. Gates the "direct provision"
  /// entry points; the server re-checks scope and answers 403.
  bool get canProvisionDirect => isGlobalAdmin || userType == regionalManager;

  /// Pull an unassigned `APPROVED` case in one's governorate onto one's own
  /// team (§4.3) — the team leader's counterpart to the desk pushing a case.
  bool get canClaimMaintenance => isGlobalAdmin || userType == teamLeader;

  /// Roles that actually drive between mosques, and so are the only ones asked
  /// for location to sort their queues nearest-first. Office roles work from a
  /// desk: prompting them would buy nothing (nearest-first sorting doc §0).
  bool get isFieldRole =>
      isGlobalAdmin || userType == teamLeader || isServiceHandler;

  /// True when the user can act on any operations-center queue. Every staff
  /// shell now carries the hub as a tab, so this holds for every staff role —
  /// asserted by the ops-permissions tests as the invariant behind that tab.
  bool get canAccessOperations =>
      canApproveEquipment ||
      canCancelEquipment ||
      canModerateWaterFlags ||
      canAccessMaintenance ||
      canFulfilContribution;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      phone: (json['phone'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      userType: (json['user_type'] ?? 'CUSTOMER').toString(),
      roleDisplay: (json['role_display'] ?? '').toString(),
      roleLevel: json['role_level'] as int? ?? 0,
      governorate: json['governorate'] is Map
          ? Governorate.fromJson(
              Map<String, dynamic>.from(json['governorate'] as Map),
            )
          : null,
      manager: json['manager'] is Map
          ? StaffRef.fromJson(Map<String, dynamic>.from(json['manager'] as Map))
          : null,
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      dateJoined: json['date_joined'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'full_name': fullName,
    'email': email,
    'user_type': userType,
    'role_display': roleDisplay,
    'role_level': roleLevel,
    'governorate': governorate?.toJson(),
    'manager': manager?.toJson(),
    'is_phone_verified': isPhoneVerified,
    'date_joined': dateJoined,
  };

  @override
  List<Object?> get props => [
    id,
    phone,
    fullName,
    email,
    userType,
    roleLevel,
    governorate,
    manager,
    isPhoneVerified,
  ];
}
