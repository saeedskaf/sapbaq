import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// A WGS84 position, in the decimal degrees the API expects.
typedef LatLng = ({double lat, double lng});

/// Why the app has (or hasn't) got a position — drives the UI hint only.
enum LocationAvailability {
  /// Not asked yet.
  unknown,
  granted,
  denied,

  /// Denied permanently: only the OS settings screen can undo it.
  deniedForever,

  /// Location services are switched off device-wide.
  serviceOff,

  /// This role isn't asked for location at all (office/back-office roles).
  notApplicable,
}

/// The single place that talks to the OS about location.
///
/// Sorting a queue nearest-first is a convenience, never a requirement: every
/// failure path here returns null and the caller simply omits `lat/lng`, so the
/// list falls back to the server's default order (sorting doc §7).
///
/// Two behaviours matter beyond that:
/// - the permission is requested **once per session** — after a refusal we stop
///   asking, so opening four queues doesn't mean four prompts;
/// - concurrent callers share one lookup, and a fresh-enough fix is reused for
///   [_cacheTtl], because the four queues typically load moments apart.
class LocationService {
  /// How long a fix stays fresh enough to reuse. A field user moving between
  /// mosques doesn't change bucket within a few minutes.
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Cap on the OS lookup: past this we'd rather show the list unsorted than
  /// keep the user waiting on a GPS lock.
  static const Duration _timeout = Duration(seconds: 8);

  LocationAvailability _state = LocationAvailability.unknown;
  LatLng? _cached;
  DateTime? _cachedAt;
  Future<LatLng?>? _inFlight;

  LocationAvailability get state => _state;

  /// Whether the permission was refused for good — the only case where sending
  /// the user to the OS settings is the honest suggestion.
  bool get isBlocked =>
      _state == LocationAvailability.deniedForever ||
      _state == LocationAvailability.serviceOff;

  /// The current position, or null when it isn't available for any reason.
  ///
  /// [isFieldRole] gates the whole thing: office roles never see a location
  /// prompt, since nearest-first sorting buys them nothing.
  Future<LatLng?> current({bool isFieldRole = true}) {
    if (!isFieldRole) {
      _state = LocationAvailability.notApplicable;
      return Future.value(null);
    }
    final cached = _cached;
    final at = _cachedAt;
    if (cached != null &&
        at != null &&
        DateTime.now().difference(at) < _cacheTtl) {
      return Future.value(cached);
    }
    // A refusal is remembered for the session: re-prompting on every screen is
    // how apps train users to deny permanently.
    if (_state == LocationAvailability.denied ||
        _state == LocationAvailability.deniedForever) {
      return Future.value(null);
    }
    return _inFlight ??= _resolve().whenComplete(() => _inFlight = null);
  }

  Future<LatLng?> _resolve() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _state = LocationAvailability.serviceOff;
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _state = LocationAvailability.deniedForever;
        return null;
      }
      if (permission == LocationPermission.denied) {
        _state = LocationAvailability.denied;
        return null;
      }
      _state = LocationAvailability.granted;

      // Prefer the OS's last fix so the first list is sorted immediately; only
      // wait on a live reading when there's nothing cached to start from.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _remember(last);
        // Refresh in the background for whoever asks next.
        unawaited(_refresh());
        return _cached;
      }
      return await _refresh();
    } catch (_) {
      // Platform quirks (no plugin on desktop, a timeout, a revoked service)
      // must never break a queue — degrade to the default order.
      return _cached;
    }
  }

  Future<LatLng?> _refresh() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: _timeout,
        ),
      );
      _remember(position);
      return _cached;
    } catch (_) {
      return _cached;
    }
  }

  /// Keeps only a position inside the ranges the API accepts — anything else is
  /// silently ignored by the server anyway, so we don't send it (§1).
  void _remember(Position position) {
    final lat = position.latitude;
    final lng = position.longitude;
    if (lat.abs() > 90 || lng.abs() > 180 || lat.isNaN || lng.isNaN) return;
    _cached = (lat: lat, lng: lng);
    _cachedAt = DateTime.now();
  }

  /// Opens the OS settings page so a permanently-denied permission can be
  /// granted; the app can't re-prompt for it itself.
  Future<void> openSettings() async {
    if (_state == LocationAvailability.serviceOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
