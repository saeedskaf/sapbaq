import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sapbaq_admin/app/app.dart';
import 'package:sapbaq_admin/core/config/environment.dart';
import 'package:sapbaq_admin/core/network/dio_client.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/core/notifications/push_notification_service.dart';
import 'package:sapbaq_admin/core/settings/settings_service.dart';
import 'package:sapbaq_admin/core/storage/secure_storage.dart';
import 'package:sapbaq_admin/features/auth/data/auth_repository.dart';
import 'package:sapbaq_admin/features/notifications/data/notifications_repository.dart';
import 'package:sapbaq_admin/firebase_options.dart';

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

  // Use the bundled fonts in assets/google_fonts/ — never fetch from
  // fonts.gstatic.com at runtime (which crashes the app when offline).
  GoogleFonts.config.allowRuntimeFetching = false;

  // Load persisted UI preferences before the first frame so there's no flash
  // of the wrong language.
  final settingsService = await SettingsService.create();

  // The active API language. Shared (by reference) between the networking layer
  // (reads it on every request) and the SettingsCubit (writes it when the user
  // switches language).
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
  // the user is authenticated, and clears it on logout. Gated behind
  // [Environment.pushEnabled] (on by default) — disable for a Firebase-less run
  // with `--dart-define=PUSH_ENABLED=false`. The try/catch keeps any init
  // failure (e.g. APNs not ready yet) from blocking startup.
  final pushNotifications = PushNotificationService(
    notifications: NotificationsRepository(dio),
    session: session,
  );
  if (Environment.pushEnabled) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      await pushNotifications.init(locale: settingsService.locale);
    } catch (error) {
      debugPrint('Push notifications disabled: $error');
    }
  }

  runApp(
    SapbaqAdminApp(
      dio: dio,
      authRepository: authRepository,
      settingsService: settingsService,
      languageCode: languageCode,
      pushNotifications: pushNotifications,
    ),
  );
}
