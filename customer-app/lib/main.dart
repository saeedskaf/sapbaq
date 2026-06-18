import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sapbaq/app/app.dart';
import 'package:sapbaq/core/network/dio_client.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/settings/settings_service.dart';
import 'package:sapbaq/core/storage/secure_storage.dart';
import 'package:sapbaq/features/auth/data/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(
    SapbaqApp(
      dio: dio,
      authRepository: authRepository,
      settingsService: settingsService,
      languageCode: languageCode,
    ),
  );
}
