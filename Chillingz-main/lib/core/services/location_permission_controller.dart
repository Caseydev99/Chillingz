import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/services/location_service.dart';
import '../../routes/app_routes.dart';
import '../navigation/app_navigator.dart';

/// Single source of truth for the device location permission.
///
/// It watches the app lifecycle, so any change made outside the app (the
/// system permission dialog, the OS settings screen) is picked up as soon as
/// the app resumes. Listeners rebuild with the fresh status and, once
/// enforcement is enabled, the user is sent back to the location permission
/// screen whenever access is missing.
class LocationPermissionController extends ChangeNotifier
    with WidgetsBindingObserver {
  LocationPermissionController._();

  static final LocationPermissionController instance =
      LocationPermissionController._();

  static const String _skippedKey = 'location_permission_skipped';

  final LocationService _locationService = LocationService();

  LocationPermission _permission = LocationPermission.denied;
  bool _serviceEnabled = false;
  bool _isRefreshing = false;
  bool _isObserving = false;
  bool _isGateVisible = false;
  bool _isEnforcementEnabled = false;
  bool _hasSkipped = false;
  Future<void>? _skipPreferenceFuture;

  LocationPermission get permission => _permission;

  bool get serviceEnabled => _serviceEnabled;

  bool get isPermissionGranted =>
      _permission == LocationPermission.always ||
      _permission == LocationPermission.whileInUse;

  bool get hasLocationAccess => isPermissionGranted && _serviceEnabled;

  bool get isPermanentlyDenied =>
      _permission == LocationPermission.deniedForever;

  bool get canRequestPermission => _permission == LocationPermission.denied;

  /// Whether the location permission screen is currently on screen.
  bool get isGateVisible => _isGateVisible;

  /// True once the user has chosen to continue without location. The app stays
  /// fully usable and the permission screen is never pushed on its own again;
  /// it only opens when the user asks for it from the location bar or settings.
  bool get hasSkipped => _hasSkipped;

  void start() {
    if (_isObserving) {
      return;
    }

    _isObserving = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(ensureSkipPreferenceLoaded());
  }

  Future<void> ensureSkipPreferenceLoaded() {
    return _skipPreferenceFuture ??= _loadSkipPreference();
  }

  Future<void> _loadSkipPreference() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _hasSkipped = preferences.getBool(_skippedKey) ?? false;
    } catch (_) {
      _hasSkipped = false;
    }
  }

  /// Records that the user chose to continue without location access.
  Future<void> markSkipped() async {
    _hasSkipped = true;
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_skippedKey, true);
    } catch (_) {
      // The in-memory flag still holds for this session.
    }
  }

  Future<void> _clearSkipped() async {
    if (!_hasSkipped) {
      return;
    }

    _hasSkipped = false;

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_skippedKey);
    } catch (_) {
      // Nothing to do; the next grant will try again.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    // Settings may change while the app is backgrounded. Refresh state for
    // listeners, but never navigate during lifecycle restoration; pushing a
    // permission route here can leave iOS/iPad on a blank transition frame.
    unawaited(refresh(enforce: false));
  }

  /// Re-reads the permission and location service status.
  ///
  /// Set [requestPermission] to also show the system dialog when the
  /// permission has not been refused permanently.
  Future<bool> refresh({
    bool requestPermission = false,
    bool enforce = false,
  }) async {
    if (_isRefreshing) {
      return hasLocationAccess;
    }

    _isRefreshing = true;

    try {
      var permission = await _locationService.checkPermissionStatus();
      if (requestPermission && permission == LocationPermission.denied) {
        permission = await _locationService.requestPermissionStatus();
      }

      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      final hasChanged =
          permission != _permission || serviceEnabled != _serviceEnabled;

      _permission = permission;
      _serviceEnabled = serviceEnabled;

      if (hasLocationAccess && _hasSkipped) {
        await _clearSkipped();
      }

      if (hasChanged) {
        notifyListeners();
      }
    } catch (_) {
      // Keep the last known status; the next refresh will try again.
    } finally {
      _isRefreshing = false;
    }

    if (enforce) {
      _showGateIfNeeded();
    }

    return hasLocationAccess;
  }

  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Entry point for the "Location preferences" setting: it sends the user to
  /// the OS settings for the app. The resume handler re-checks the status and
  /// shows the permission screen when they come back without granting access.
  Future<void> openLocationPreferences() async {
    await openAppSettings();
  }

  /// Starts guarding the app. Called once the startup gate has been resolved
  /// so the screen is never pushed on top of the splash.
  void enableEnforcement() {
    _isEnforcementEnabled = true;
  }

  void disableEnforcement() {
    _isEnforcementEnabled = false;
  }

  void setGateVisible(bool isVisible) {
    _isGateVisible = isVisible;
  }

  void _showGateIfNeeded() {
    if (!_isEnforcementEnabled ||
        _isGateVisible ||
        _hasSkipped ||
        hasLocationAccess) {
      return;
    }

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _isGateVisible = true;
    navigator.pushNamed<bool>(AppRoutes.locationPermission);
  }
}
