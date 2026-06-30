import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/core/notifications/notification_deep_link.dart';
import 'package:sapbaq_admin/features/notifications/data/notifications_repository.dart';

/// Connects Firebase Cloud Messaging to the backend device registry.
///
/// Lifecycle, driven by [SessionManager]:
///  * on [AuthStatus.authenticated] → request the OS notification permission,
///    fetch the FCM token and `POST` it to `/notifications/devices/` so the
///    backend can target this device; keep it fresh via [onTokenRefresh].
///  * on [AuthStatus.unauthenticated] → `DELETE` the token from the backend and
///    delete it locally, so a logged-out device stops receiving pushes.
///
/// Registration is best-effort — a failure here never blocks the UI. The OS
/// shows background/terminated notifications in the tray itself; this service
/// only adds foreground display (via flutter_local_notifications).
///
/// [Firebase.initializeApp] and the background handler are set up in `main()`
/// before this service is created.
class PushNotificationService {
  PushNotificationService({
    required NotificationsRepository notifications,
    required SessionManager session,
  })  : _notifications = notifications,
        _session = session;

  final NotificationsRepository _notifications;
  final SessionManager _session;

  // Resolved lazily: accessing FirebaseMessaging.instance touches Firebase.app(),
  // which throws [core/no-app] until Firebase.initializeApp() has run. main()
  // initializes Firebase before calling init(), so every use below is safe.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<AuthStatus>? _authSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  /// Set when the user taps a notification (foreground/background or a cold
  /// launch); the app observes this and navigates, then clears it (§14).
  final ValueNotifier<NotificationRoute?> pendingRoute = ValueNotifier(null);

  /// The token currently registered with the backend, kept so we can unregister
  /// the exact one on logout.
  String? _registeredToken;
  bool _registered = false;

  /// Android channel used to surface foreground messages (Android only shows
  /// background/terminated notifications on its own, not foreground ones).
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sapbaq_default',
    'General',
    description: 'Order assignments and delivery updates.',
    importance: Importance.high,
  );

  /// Idempotent: call once from `main()` after Firebase is initialized.
  Future<void> init() async {
    await _setupForegroundDisplay();

    _foregroundSub = FirebaseMessaging.onMessage.listen(_showForeground);
    // iOS: also let the system present the banner while in the foreground.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Deep-link when a tapped notification opens or resumes the app, including
    // a cold launch from terminated (getInitialMessage). Guarded so a failure
    // here never blocks token registration or the rest of startup.
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) _handleOpened(initialMessage);
    } catch (error) {
      debugPrint('getInitialMessage skipped: $error');
    }

    // Register/unregister as the session changes. Subscribe first, then check
    // the current status so we don't miss a transition that already happened.
    _authSub = _session.stream.listen(_onAuthStatus);
    if (_session.status == AuthStatus.authenticated) {
      unawaited(_register());
    }
  }

  Future<void> _onAuthStatus(AuthStatus status) async {
    if (status == AuthStatus.authenticated) {
      await _register();
    } else if (status == AuthStatus.unauthenticated) {
      await _unregister();
    }
    // unknown / guest: nothing to do.
  }

  Future<void> _register() async {
    if (_registered) return;
    _registered = true;

    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _registered = false; // user may enable it later; retry on next login.
      return;
    }

    String? token;
    try {
      token = await _messaging.getToken();
    } catch (error) {
      // On iOS before APNs is wired up, getToken throws `apns-token-not-set`.
      // Skip registration gracefully (retry on the next login / token refresh)
      // instead of letting the exception surface and break a debug run.
      debugPrint('FCM token unavailable yet (will retry): $error');
      _registered = false;
      return;
    }
    if (token == null) {
      _registered = false; // e.g. iOS before APNs is configured — retry later.
      return;
    }
    await _sendToken(token);

    // Keep the backend in sync when FCM rotates the token.
    _tokenRefreshSub ??= _messaging.onTokenRefresh.listen(_sendToken);
  }

  Future<void> _sendToken(String token) async {
    try {
      await _notifications.registerDevice(token: token, platform: _platform);
      _registeredToken = token;
    } catch (_) {
      // Best-effort: a transient failure shouldn't surface to the user.
    }
  }

  Future<void> _unregister() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    final token = _registeredToken ?? await _messaging.getToken();
    if (token != null) {
      try {
        await _notifications.unregisterDevice(token);
      } catch (_) {
        // Ignore — the backend also prunes stale tokens on its own.
      }
    }
    // Drop the local token so the next login gets a fresh device identity.
    try {
      await _messaging.deleteToken();
    } catch (_) {}
    _registeredToken = null;
    _registered = false;
  }

  Future<void> _setupForegroundDisplay() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // firebase_messaging already owns the iOS permission prompt.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Resolves a tapped message's deep link and publishes it for the app to
  /// navigate. The backend sends `notification_type` and ids in `data`.
  void _handleOpened(RemoteMessage message) {
    final data = message.data;
    final type = (data['notification_type'] ?? data['type'] ?? '').toString();
    final route = resolveNotificationRoute(
      type,
      orderId: notificationDataInt(data, 'order_id'),
      destinationId: notificationDataInt(data, 'destination_id'),
      approvalId: notificationDataInt(data, 'approval_id'),
      escalationId: notificationDataInt(data, 'escalation_id'),
    );
    if (route != null) pendingRoute.value = route;
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  Future<void> dispose() async {
    await _authSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    pendingRoute.dispose();
  }
}
