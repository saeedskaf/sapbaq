import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sapbaq/core/storage/secure_storage.dart';
import 'package:uuid/uuid.dart';

/// The device's identity for **device trust**.
///
/// [deviceId] is a random id generated once per install and kept in
/// [SecureStorage] (surviving logout) — it is what the backend binds trust to,
/// sent on every OTP/passcode/verify call. [deviceName] is a human label
/// ("iPhone 14", "Pixel 8") shown in the trusted-device list; it is best-effort
/// and never used for security.
class DeviceIdentity {
  final SecureStorage _storage;
  final DeviceInfoPlugin _info;

  DeviceIdentity({SecureStorage? storage, DeviceInfoPlugin? info})
      : _storage = storage ?? secureStorage,
        _info = info ?? DeviceInfoPlugin();

  /// Return the stored device id, generating and persisting one on first use.
  Future<String> deviceId() async {
    final existing = await _storage.getDeviceId();
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await _storage.saveDeviceId(id);
    return id;
  }

  /// A best-effort human name for this device (for the trusted-device list).
  /// Falls back to a generic label when the platform lookup fails.
  Future<String> deviceName() async {
    try {
      if (Platform.isIOS) {
        final ios = await _info.iosInfo;
        // e.g. "iPhone 14" — utsname is a technical code, so prefer the name.
        final name = ios.name.trim();
        return name.isNotEmpty ? name : ios.utsname.machine;
      }
      if (Platform.isAndroid) {
        final android = await _info.androidInfo;
        final brand = android.brand.trim();
        final model = android.model.trim();
        final label = [brand, model].where((p) => p.isNotEmpty).join(' ').trim();
        return label.isNotEmpty ? label : 'Android';
      }
    } catch (e) {
      debugPrint('DeviceIdentity.deviceName failed: $e');
    }
    return 'Unknown device';
  }
}
