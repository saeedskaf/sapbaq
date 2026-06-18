import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sapbaq_admin/app/app.dart';
import 'package:sapbaq_admin/core/network/dio_client.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/core/storage/secure_storage.dart';
import 'package:sapbaq_admin/features/auth/data/auth_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Use the bundled fonts in assets/google_fonts/ — never fetch from
  // fonts.gstatic.com at runtime (which crashes the app when offline).
  GoogleFonts.config.allowRuntimeFetching = false;

  final session = SessionManager();
  final dio = DioClient.create(storage: secureStorage, session: session);
  final authRepository = AuthRepository(
    dio: dio,
    storage: secureStorage,
    session: session,
  );

  runApp(SapbaqAdminApp(dio: dio, authRepository: authRepository));
}
