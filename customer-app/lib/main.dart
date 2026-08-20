import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sapbaq/app/app.dart';
import 'package:sapbaq/core/network/dio_client.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/notifications/push_notification_service.dart';
import 'package:sapbaq/core/config/environment.dart';
import 'package:sapbaq/core/settings/settings_service.dart';
import 'package:sapbaq/core/storage/secure_storage.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';
import 'package:sapbaq/features/notifications/data/notifications_repository.dart';
import 'package:sapbaq/firebase_options.dart';

/// Handles pushes that arrive while the app is backgrounded or terminated.
/// Must be a top-level function — it runs in its own isolate, so Firebase has to
/// be initialized again here. Android renders notification-type messages in the
/// tray automatically, so no extra work is required.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Which payment route this build will actually take, printed once at startup.
  //
  // `PAY_EMBED_URL` is a compile-time define, so which route a build takes is
  // decided before it runs and is invisible afterwards. It used to default to
  // empty, and a `flutter run` that forgot the define silently produced a
  // hosted-page-only build — behaving exactly as designed and looking exactly
  // like a regression. That cost a full test cycle and a round of backend
  // diagnosis, because the only evidence was a request that *wasn't* in the
  // log. The default now points at the real page, so the line below normally
  // reads ON; it still earns its place for the builds that override it off.
  if (kDebugMode) {
    debugPrint(
      Environment.embeddedCheckoutEnabled
          ? '[payments] embedded checkout ON → ${Environment.payEmbedUrl}'
          : '[payments] embedded checkout OFF — hosted page only '
                '(PAY_EMBED_URL was overridden to empty)',
    );
  }

  // Use the bundled fonts in assets/google_fonts/ — never fetch from
  // fonts.gstatic.com at runtime (which crashed the app when offline).
  GoogleFonts.config.allowRuntimeFetching = false;

  // Load persisted UI preferences before the first frame so there's no flash
  // of the wrong theme/language.
  final settingsService = await SettingsService.create();

  // The active API language. Shared (by reference) between the networking
  // layer (reads it on every request) and the SettingsCubit (writes it when
  // the user switches language).
  final languageCode = ValueNotifier<String>(
    settingsService.locale.languageCode,
  );

  final session = SessionManager();
  final dio = DioClient.create(
    storage: secureStorage,
    session: session,
    language: languageCode,
  );
  final authRepository = AuthRepository(
    dio: dio,
    storage: secureStorage,
    session: session,
  );

  // Push notifications: registers this device's FCM token with the backend once
  // the user is authenticated, and clears it on logout. Wrapped in try/catch so
  // that before `flutterfire configure` generates firebase_options.dart (Firebase
  // unavailable), the rest of the app still runs — only push is disabled.
  final pushNotifications = PushNotificationService(
    notifications: NotificationsRepository(dio),
    session: session,
    languageCode: languageCode,
  );
  // Unregister this device's FCM token during logout, while the access token is
  // still valid, so the authenticated DELETE doesn't 401 (see
  // FLUTTER_FCM_DEVICE_UNREGISTER_NOTE.md).
  authRepository.onBeforeLogout = pushNotifications.unregisterForLogout;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await pushNotifications.init(locale: settingsService.locale);
  } catch (error) {
    debugPrint('Push notifications disabled: $error');
  }

  runApp(
    SapbaqApp(
      dio: dio,
      authRepository: authRepository,
      settingsService: settingsService,
      languageCode: languageCode,
      pushNotifications: pushNotifications,
    ),
  );
}
