import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/features/notifications/data/notifications_repository.dart';
import 'package:sapbaq_admin/l10n/app_localizations.dart';

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
    required ValueNotifier<String> languageCode,
  }) : _notifications = notifications,
       _session = session,
       _languageCode = languageCode;

  final NotificationsRepository _notifications;
  final SessionManager _session;

  /// The active UI language (`ar`/`en`), shared with the networking layer. Sent
  /// with the device registration and used to pick the right foreground copy.
  final ValueNotifier<String> _languageCode;

  /// Normalized to a supported push language (falls back to Arabic).
  String get _lang => _languageCode.value == 'en' ? 'en' : 'ar';

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

  /// The raw `data` of a tapped notification (foreground/background or a cold
  /// launch); the app observes this, resolves it against the signed-in role and
  /// navigates, then clears it (§14).
  ///
  /// The payload is held unresolved because the target depends on the reader's
  /// role (an imam and a staff member land on different screens for the same
  /// case), and a cold launch establishes the session only after the tap.
  final ValueNotifier<Map<String, dynamic>?> pendingNotification =
      ValueNotifier(null);

  /// The token currently registered with the backend, kept so we can unregister
  /// the exact one on logout.
  String? _registeredToken;
  bool _registered = false;

  /// Foreground pushes, so app-level state (badges, inboxes) can refresh while
  /// the user is looking at the app instead of going stale.
  final StreamController<RemoteMessage> _foregroundMessages =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onForegroundMessage => _foregroundMessages.stream;

  /// The same stream reduced to each push's `data` map — what badge/inbox
  /// consumers actually read.
  Stream<Map<String, dynamic>> get onForegroundData =>
      _foregroundMessages.stream.map((message) => message.data);

  /// The Android channel every notification lands on — the one the backend
  /// targets via `channel_id`, and the one whose sound the OS plays.
  ///
  /// Bump the `_vN` suffix whenever the channel's **sound or importance**
  /// changes: Android freezes those at creation time and silently ignores edits
  /// to an existing channel. Swapping the *contents* of `res/raw/notify.wav`
  /// under the same name needs no bump — the channel stores the resource URI,
  /// not the audio.
  static const String channelId = 'sapbaq_alerts_v1';

  /// The pre-sound channel, deleted on startup so it stops showing up as an
  /// orphaned entry in the system notification settings of existing installs.
  static const String _legacyChannelId = 'sapbaq_default';

  /// `android/app/src/main/res/raw/notify.wav` (referenced without extension).
  static const String _soundResource = 'notify';

  AndroidNotificationChannel? _channel;

  /// Idempotent: call once from `main()` after Firebase is initialized.
  /// [locale] localizes the channel name/description shown in Android's system
  /// notification settings.
  Future<void> init({required Locale locale}) async {
    await _setupForegroundDisplay(locale);

    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    // iOS: also let the system present the banner while in the foreground. The
    // sound played is the one the backend puts in `aps.sound` (notify.caf).
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

    // A cold launch from tapping one of *our* foreground-shown Android local
    // notifications arrives here, not through getInitialMessage.
    try {
      final launch = await _localNotifications
          .getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final payload = launch!.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          _publishTapFromPayload(payload);
        }
      }
    } catch (error) {
      debugPrint('notification launch details skipped: $error');
    }

    // Re-register (same token, new language) when the user switches the app
    // language, so the backend localizes future background pushes correctly.
    _languageCode.addListener(_onLanguageChanged);

    // Register/unregister as the session changes. Subscribe first, then check
    // the current status so we don't miss a transition that already happened.
    _authSub = _session.stream.listen(_onAuthStatus);
    if (_session.status == AuthStatus.authenticated) {
      unawaited(_register());
    }
  }

  void _onLanguageChanged() {
    final token = _registeredToken;
    if (_registered && token != null) unawaited(_sendToken(token));
  }

  /// Re-applies the channel's localized name/description after a language
  /// switch. Android allows updating those two fields on an existing channel
  /// (unlike sound/importance), so this is safe to call any time.
  Future<void> updateChannelLocalization(Locale locale) =>
      _createChannel(locale);

  Future<void> _onAuthStatus(AuthStatus status) async {
    if (status == AuthStatus.authenticated) {
      await _register();
    } else if (status == AuthStatus.unauthenticated) {
      // Only local teardown here — the session's tokens are already gone by the
      // time this fires, so the *network* unregister must happen earlier, via
      // [unregisterForLogout]. See the note on that method.
      await _teardownLocal();
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

    // Subscribe BEFORE fetching the token, and keep the subscription even when
    // the fetch below fails. On iOS getToken() throws `apns-token-not-set`
    // until APNs registration completes — which routinely happens because the
    // session restores (and we land here) within a second of launch. FCM mints
    // the token moments later and delivers it here. Subscribing *after*
    // getToken() meant that a cold-start failure was never retried and the
    // device stayed unregistered — receiving no pushes at all — for the whole
    // session.
    _tokenRefreshSub ??= _messaging.onTokenRefresh.listen(_sendToken);

    // Give APNs a moment to hand us its token so the first getToken() usually
    // succeeds; onTokenRefresh above is the safety net if it doesn't.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _awaitApnsToken();
    }

    String? token;
    try {
      token = await _messaging.getToken();
    } catch (error) {
      debugPrint('FCM token not ready; onTokenRefresh will deliver it: $error');
      return; // stay "registered": the refresh listener finishes the job.
    }
    if (token == null) return; // same — onTokenRefresh will deliver it.
    await _sendToken(token);
  }

  /// Polls for the APNs token (iOS only) for up to ~2.4s. Returns as soon as
  /// it's available, or gives up quietly — [_register] can proceed either way.
  Future<void> _awaitApnsToken() async {
    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        if (await _messaging.getAPNSToken() != null) return;
      } catch (_) {
        // Not ready yet.
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }

  /// Backoff between registration attempts. Short and bounded: a device that
  /// stays unregistered receives no pushes for the whole session, so a flaky
  /// network at login is worth riding out — but after these, we stop and wait
  /// for the next trigger (login, token refresh, language switch).
  static const List<Duration> _registerRetryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 20),
    Duration(minutes: 1),
  ];

  /// Bumped on every [_sendToken] call and on teardown, so a superseded retry
  /// chain (new token arrived, or the user logged out) stops quietly.
  int _sendGeneration = 0;

  Future<void> _sendToken(String token) async {
    final generation = ++_sendGeneration;
    for (var attempt = 0; ; attempt++) {
      if (generation != _sendGeneration || !_registered) return;
      try {
        await _notifications.registerDevice(
          token: token,
          platform: _platform,
          language: _lang,
        );
        _registeredToken = token;
        return;
      } catch (_) {
        // Best-effort: a transient failure shouldn't surface to the user.
        if (attempt >= _registerRetryDelays.length) return;
        await Future<void>.delayed(_registerRetryDelays[attempt]);
      }
    }
  }

  /// Unregisters this device's FCM token with the backend, then tears down
  /// locally. Call this **while the access token is still valid** — i.e. from
  /// `logout()` *before* the session clears its tokens. The DELETE endpoint is
  /// authenticated, so reacting to the `unauthenticated` status instead would
  /// send it after the Bearer is already gone and earn a 401 on every logout
  /// (see FLUTTER_FCM_DEVICE_UNREGISTER_NOTE.md). Safe to call when push is
  /// disabled or no token was ever registered.
  Future<void> unregisterForLogout() async {
    String? token = _registeredToken;
    if (token == null) {
      // May throw `apns-token-not-set` on iOS (e.g. the Simulator, or before
      // APNs registration completes) — tolerate it.
      try {
        token = await _messaging.getToken();
      } catch (_) {
        token = null;
      }
    }
    if (token != null) {
      try {
        await _notifications.unregisterDevice(token);
      } catch (_) {
        // Ignore — the backend also prunes stale tokens on its own.
      }
    }
    await _teardownLocal();
  }

  /// Offline teardown, no network. Runs both from [unregisterForLogout] and
  /// reactively when the session ends for any other reason (e.g. a failed token
  /// refresh, where there's no valid Bearer left to unregister with anyway).
  /// Idempotent — logout runs it twice (once here, once via the status event).
  Future<void> _teardownLocal() async {
    _sendGeneration++; // abort any in-flight registration retry chain.
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    // Drop the local token so the next login gets a fresh device identity.
    try {
      await _messaging.deleteToken();
    } catch (_) {}

    // Don't leave the previous user's notifications sitting in the tray.
    try {
      await _localNotifications.cancelAll();
    } catch (_) {}

    _registeredToken = null;
    _registered = false;
  }

  Future<void> _setupForegroundDisplay(Locale locale) async {
    // The status-bar icon must be the monochrome one, not the launcher icon
    // (Android renders a colored launcher icon as a white square).
    const android = AndroidInitializationSettings(
      '@drawable/ic_stat_notification',
    );
    // firebase_messaging already owns the iOS permission prompt.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: _onLocalTap,
    );
    await _createChannel(locale);
  }

  Future<void> _createChannel(Locale locale) async {
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    final l10n = await AppLocalizations.delegate.load(locale);
    final channel = AndroidNotificationChannel(
      channelId,
      l10n.notificationChannelName,
      description: l10n.notificationChannelDescription,
      importance: Importance.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(_soundResource),
    );
    await android.createNotificationChannel(channel);
    _channel = channel;

    // Retire the old soundless channel from upgraded installs.
    try {
      await android.deleteNotificationChannel(channelId: _legacyChannelId);
    } catch (_) {
      // Never existed on this device — nothing to clean up.
    }
  }

  /// A tapped FCM notification (background/terminated) — deep-link from it.
  void _handleOpened(RemoteMessage message) => _publishTap(message.data);

  /// A tapped foreground (Android) local notification — parse the payload we
  /// stored on it and route exactly like an FCM-delivered tap.
  void _onLocalTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) _publishTapFromPayload(payload);
  }

  void _publishTapFromPayload(String payload) {
    try {
      _publishTap(Map<String, dynamic>.from(jsonDecode(payload) as Map));
    } catch (_) {
      // Malformed payload — nothing to navigate to.
    }
  }

  /// Publishes a tapped notification's `data` for the app to resolve against
  /// the signed-in role and navigate (see [pendingNotification]).
  void _publishTap(Map<String, dynamic> data) =>
      pendingNotification.value = data;

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    // Let app-level state (badges, inboxes) react before we draw anything —
    // this fires on every platform.
    if (!_foregroundMessages.isClosed) _foregroundMessages.add(message);

    // iOS presents foreground notifications itself (see init's
    // setForegroundNotificationPresentationOptions) — but only when the push
    // carries an aps alert (a `notification` block). Drawing a local one too
    // would duplicate those, so on iOS we only draw for data-only pushes,
    // which the system silently swallows in the foreground. Android never
    // auto-presents in the foreground, so it always needs the local draw. The
    // data rides along as the payload so a tap deep-links via [_onLocalTap].
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    if (!isAndroid && message.notification != null) return;

    // The Android channel is created in init; without it the OS would drop
    // the notification. Irrelevant on iOS (no channels).
    final channel = _channel;
    if (isAndroid && channel == null) return;

    // Prefer the copy matching the CURRENT UI language: every push carries both
    // languages in `data` (title_ar/title_en/body_ar/body_en), so a user who
    // just switched language sees the right text even before re-registering.
    // Then the `notification` block (server-resolved to this device's
    // registered language — more likely right than the fixed-language keys),
    // then Arabic, then the legacy `data['title']`.
    final notification = message.notification;
    final data = message.data;
    final title =
        data['title_$_lang']?.toString() ??
        notification?.title ??
        data['title_ar']?.toString() ??
        data['title']?.toString();
    final body =
        data['body_$_lang']?.toString() ??
        notification?.body ??
        data['body_ar']?.toString() ??
        data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return; // A genuinely silent data push — nothing to display.
    }

    await _localNotifications.show(
      id: _notificationId(message),
      title: title,
      body: body,
      payload: jsonEncode(message.data),
      notificationDetails: NotificationDetails(
        android: channel == null
            ? null
            : AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                importance: Importance.high,
                priority: Priority.high,
                icon: '@drawable/ic_stat_notification',
                // Long Arabic bodies otherwise truncate to a single line with
                // no way to expand them.
                styleInformation: BigTextStyleInformation(
                  body ?? '',
                  contentTitle: title,
                ),
              ),
        // The data-only iOS path: same custom tone the backend puts in
        // `aps.sound` on alert-bearing pushes (ios/Runner/notify.caf).
        iOS: const DarwinNotificationDetails(sound: 'notify.caf'),
      ),
    );
  }

  /// A stable, non-negative 32-bit id so redelivery of the same message updates
  /// its notification instead of stacking a duplicate.
  int _notificationId(RemoteMessage message) {
    final key = message.messageId ?? '';
    if (key.isEmpty) return _fallbackId++ & 0x7fffffff;
    return key.hashCode & 0x7fffffff;
  }

  int _fallbackId = 0;

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  Future<void> dispose() async {
    _languageCode.removeListener(_onLanguageChanged);
    await _authSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _foregroundMessages.close();
    pendingNotification.dispose();
  }
}
